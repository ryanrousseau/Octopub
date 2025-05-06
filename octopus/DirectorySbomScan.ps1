Write-Host "Pulling Trivy Docker Image"
Write-Host "##octopus[stdout-verbose]"
docker pull ghcr.io/aquasecurity/trivy
Write-Host "##octopus[stdout-default]"

$SUCCESS = 0

# Find all bom.json files
$bomFiles = Get-ChildItem -Path "." -Filter "bom.json" -Recurse -File

if ($bomFiles.Count -eq 0) {
    Write-Host "No bom.json files found in the current directory."
    exit 1
}

foreach ($file in $bomFiles) {
    Write-Host "Scanning $($file.FullName)"

    # Delete any existing report file
    if (Test-Path "$PWD/depscan-bom.json") {
        Remove-Item "$PWD/depscan-bom.json" -Force
    }

    # Generate the report, capturing the output
    try {
        $OUTPUT = docker run --rm -v "$($file.FullName):/input/$($file.Name)" ghcr.io/aquasecurity/trivy sbom -q "/input/$($file.Name)"
        $exitCode = $LASTEXITCODE
    }
    catch {
        $OUTPUT = $_.Exception.Message
        $exitCode = 1
    }

    # Run again to generate the JSON output
    docker run --rm -v "${PWD}:/output" -v "$($file.FullName):/input/$($file.Name)" ghcr.io/aquasecurity/trivy sbom -q -f json -o /output/depscan-bom.json "/input/$($file.Name)"

    # Octopus Deploy artifact
    New-OctopusArtifact "$PWD/depscan-bom.json"

    # Parse JSON output to count vulnerabilities
    $jsonContent = Get-Content -Path "depscan-bom.json" | ConvertFrom-Json
    $CRITICAL = ($jsonContent.Results | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $HIGH = ($jsonContent.Results | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_.Severity -eq "HIGH" }).Count

    if ("#{Octopus.Environment.Name}" -eq "Security") {
        Write-Highlight "🟥 $CRITICAL critical vulnerabilities"
        Write-Highlight "🟧 $HIGH high vulnerabilities"
    }

    # Set success to 1 if exit code is not zero
    if ($exitCode -ne 0) {
        $SUCCESS = 1
    }

    # Print the output
    $OUTPUT | ForEach-Object {
        if ($_.Length -gt 0) {
            Write-Host $_
        }
    }
}

# Cleanup
for ($i = 1; $i -le 10; $i++) {
    try {
        if (Test-Path "bundle") {
            Set-ItemProperty -Path "bundle" -Name IsReadOnly -Value $false -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path "bundle" -Recurse -Force -ErrorAction Stop
            break
        }
    }
    catch {
        Write-Host "Attempting to clean up files"
        Start-Sleep -Seconds 1
    }
}

# Set Octopus variable
Set-OctopusVariable -Name "VerificationResult" -Value $SUCCESS

exit 0