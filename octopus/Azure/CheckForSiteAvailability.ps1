# Define parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$AzureSiteName
)

# Configure payload
$jsonPayload = @{
  "name" = "$AzureSiteName"
  "type" = "Microsoft.Web/sites"
  "isFQDN" = $false
}

# Construct header
$headers = @{
  Authorization = "Bearer #{Octopus.Action[Get Azure Access Token].Output.AzureToken}"
  ContentType = "application/json"
}

# Fix ANSI Color on PWSH Core issues when displaying objects
if ($PSEdition -eq "Core") {
    $PSStyle.OutputRendering = "PlainText"
}

$response = (Invoke-RestMethod -Method Post -Uri "https://management.azure.com/subscriptions/#{Project.Azure.Account.SubscriptionNumber}/providers/Microsoft.Web/checknameavailability?api-version=2024-04-01" -Body $jsonPayload -Headers $headers)

# Set output variable
Set-OctopusVariable -Name NameAvailable -Value $response.nameAvailable

if ($response.nameAvailable -ne $True)
{
  Write-Highlight "The Function Name of $AzureSiteName is already in use, please change the Project Variable Project.Azure.Function.Octopub.Products.Name to something else."
}
else
{
  Write-Host "Function name available!"
}
