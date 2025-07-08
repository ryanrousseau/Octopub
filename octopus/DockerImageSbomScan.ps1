Write-Host "Pulling Trivy Docker Image"
Write-Host "##octopus[stdout-verbose]"
docker pull ghcr.io/aquasecurity/trivy
Write-Host "##octopus[stdout-default]"

# Extract files from the Docker image
Write-Host "Extracting files from Docker image..."
$IMAGE_NAME = "#{Application.Image}"
$CONTAINER_NAME = "temporary"

Write-Host "Extracting $IMAGE_NAME"

# Create directory if it doesn't exist
New-Item -Path "extracted_files" -ItemType Directory -Force | Out-Null

Write-Host "##octopus[stdout-verbose]"
# Create a temporary container
docker create --name $CONTAINER_NAME --entrypoint='' $IMAGE_NAME /bin/sleep 600 2>&1

Start-Sleep 5

docker logs $CONTAINER_NAME 2>&1

# Export the container's root filesystem
# PowerShell equivalent for tar extraction
docker export $CONTAINER_NAME | tar --wildcards --wildcards-match-slash -xvf - -C "extracted_files" "**/bom.json" 2>&1

# Remove the temporary container
docker rm $CONTAINER_NAME 2>&1
Write-Host "##octopus[stdout-default]"

$TIMESTAMP = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$SUCCESS = 0

# Find all bom.json files
$bomFiles = Get-ChildItem -Path "." -Filter "bom.json" -Recurse -File

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