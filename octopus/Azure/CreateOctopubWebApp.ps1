# Get variables
$resourceGroupName = "#{Project.Azure.ResourceGroup.Name}"
$appServiceName = "#{Project.Azure.WebApp.ServicePlan.Name}"
$azureLocation = "#{Project.Azure.Location}"
$webAppName = "#{Project.Azure.WebApp.Octopub.Name}"
$skuCode = "#{Project.Azure.WebApp.ServicePlan.SKU}"

# Fix ANSI Color on PWSH Core issues when displaying objects
if ($PSEdition -eq "Core") {
    $PSStyle.OutputRendering = "PlainText"
}

# Create App Service
Write-Host "Creating $webAppName app ..."
$webApp = (az webapp create --name $webAppName --plan $appServiceName --resource-group $resourceGroupName --sitecontainers-app $true  | ConvertFrom-Json)

if ($skuCode.StartsWith("S") -or $skuCode.StartsWith("P"))
{
    # Create deployment slots
    Write-Host "Creating deployment slots ..."
    az webapp deployment slot create --resource-group $resourceGroupName --name $webAppName --slot "staging"
}
else
{
    Write-Highlight "Unable to create deployment slots on App Service Plans of $skuCode"
}

Write-Host "Creating Octopus Azure Web App target for $appServiceName"
New-OctopusAzureWebAppTarget -Name $webAppName -AzureWebApp $webAppName -AzureResourceGroupName $resourceGroupName -OctopusAccountIdOrName $azureAccount -OctopusRoles "Octopub" -updateIfExisting
