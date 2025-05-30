Write-Host "Pulling octopusdeploylabs/python-workertools Docker Image"
Write-Host "##octopus[stdout-verbose]"
docker pull ghcr.io/octopusdeploylabs/python-workertools
Write-Host "##octopus[stdout-default]"

Write-Host "##octopus[stdout-verbose]"
Get-ChildItem -Path "." | Out-String
Write-Host "##octopus[stdout-default]"

# Find all sam files
$currentDirectoryName = Split-Path -Path $PWD -Leaf
$path = if ($currentDirectoryName -eq "octopus") {
    ".."
} else {
    "."
}

$samFiles = Get-ChildItem -Path $path -Filter "sam*.yaml" -Recurse -File

if ($samFiles.Count -eq 0) {
    Write-Host "No SAM files found in the current directory."
    exit 0
}

foreach ($file in $samFiles) {
    Write-Host "Scanning $($file.FullName)"
    $fileWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $reportFilePath = "$PWD/scan-$fileWithoutExtension.log"
    
    # Delete any existing report file
    if (Test-Path $reportFilePath) {
        Remove-Item $reportFilePath -Force
    }

    # Generate the report, capturing the output
    try {
        $OUTPUT = docker run --rm  -v "$($file.FullName):/input/$($file.Name)" ghcr.io/octopusdeploylabs/python-workertools sh -c "pip install checkov --root-user-action=ignore && checkov -f /input/$($file.Name)"
        $exitCode = $LASTEXITCODE
    }
    catch {
        $OUTPUT = $_.Exception.Message
        $exitCode = 1
    }
    
    
    # Print and capture the output
    New-Item -Type File -Path $reportFilePath | Out-Null
    $OUTPUT | ForEach-Object {
        if ($_.Length -gt 0) {
            Write-Output $_
            Add-Content -Path $reportFilePath -Value $_
        }
        
    }

    # Octopus Deploy artifact
    New-OctopusArtifact $reportFilePath

    if ($exitCode -ne 0) {
        Write-Warning "Checkov scan failed with exit code $exitCode"
        exit 0
    }
}
