Write-Host "Downloading Trivy"
Write-Host "##octopus[stdout-verbose]"
$trivyUrl = "https://github.com/aquasecurity/trivy/releases/download/v0.64.1/trivy_0.64.1_Linux-64bit.tar.gz"
$trivyOutputPath = "trivy.tar.gz"
Invoke-WebRequest -Uri $trivyUrl -OutFile $trivyOutputPath -UseBasicParsing
tar -xzf "trivy.tar.gz"
ls -la trivy
Write-Host "##octopus[stdout-default]"

Write-Host "Downloading Skopeo"
Write-Host "##octopus[stdout-verbose]"

$skopeoUrl = "https://github.com/lework/skopeo-binary/releases/download/v1.19.0/skopeo-linux-amd64"
$skopeoOutputPath = "skopeo"
Invoke-WebRequest -Uri $skopeoUrl -OutFile $skopeoOutputPath -UseBasicParsing
chmod +x $skopeoOutputPath
ls -la $skopeoOutputPath
Write-Host "##octopus[stdout-default]"

Write-Host "Downloading umoci binary"
Write-Host "##octopus[stdout-verbose]"

# Download umoci binary
$url = "https://github.com/opencontainers/umoci/releases/download/v0.5.0/umoci.linux.amd64"
$outputPath = "umoci"
Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
chmod +x $outputPath
ls -la $outputPath
Write-Host "##octopus[stdout-default]"

# Extract files from the Docker image
Write-Host "Downloading image #{Application.Image}"
Write-Host "##octopus[stdout-verbose]"
$IMAGE_NAME = "#{Application.Image}"
./skopeo copy --insecure-policy "docker://$IMAGE_NAME" "oci:image:latest" 2>&1
Write-Host "##octopus[stdout-default]"

Write-Host "Extracting files from Docker image #{Application.Image}"
Write-Host "##octopus[stdout-verbose]"
./umoci unpack --image image --rootless bundle 2>&1
Write-Host "##octopus[stdout-default]"

$TIMESTAMP = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$SUCCESS = 0

# Find all bom.json files
$bomFiles = Get-ChildItem -Path "." -Filter "bom.json" -Recurse -File

foreach ($file in $bomFiles) {
    Write-Host "Scanning $($file.FullName)"
    Get-Content -Path $file.FullName | Out-String | Write-Host

    # Delete any existing report file
    if (Test-Path "$PWD/depscan-bom.json") {
        Remove-Item "$PWD/depscan-bom.json" -Force
    }

    # Generate the report, capturing the output
    try {
        $OUTPUT = ./trivy sbom "$($file.FullName)"
        $exitCode = $LASTEXITCODE
    }
    catch {
        $OUTPUT = $_.Exception.Message
        $exitCode = 1
    }

    # Run again to generate the JSON output
    ./trivy sbom -f json -o depscan-bom.json "$($file.FullName)"

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