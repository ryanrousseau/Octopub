param(
    [Parameter(Mandatory=$true)]
    [string]$URL,

    [Parameter(Mandatory=$false)]
    [string]$Body = $null
)

Write-Host "Testing $URL"

try {
    $response = Invoke-WebRequest -Uri $URL `
        -Method POST `
        -ContentType "application/json" `
        -Body $Body `
        -UseBasicParsing

    if ($response.StatusCode -eq 200) {
        Write-Host "Success: HTTP 200"
    } else {
        Write-Host "Failed: HTTP $($response.StatusCode)"
        exit 1
    }
} catch {
    Write-Host "Failed: HTTP $($_.Exception.Response.StatusCode.value__)"
    exit 1
}