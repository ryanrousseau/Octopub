# Get variables
$resourceGroupName = "#{Project.Azure.ResourceGroup.Name}"
$appServiceName = "#{Project.Azure.Function.Octopub.Products.Name}"
$appServiceRuntime = "#{Project.Azure.Function.Octopub.Products.Runtime}"
$osType = "#{Project.Azure.Function.Octopub.Products.OS}"
$functionsVersion = [int]"#{Project.Azure.Function.Octopub.Products.Version}"
$azureLocation = "#{Project.Azure.Location}"
$azureAccount = "#{Project.Azure.Account}"
$storageAccountName = "#{Project.Azure.StorageAccount.Name}"

# Fix ANSI Color on PWSH Core issues when displaying objects
if ($PSEdition -eq "Core") {
    $PSStyle.OutputRendering = "PlainText"
}

# Create App Service
Write-Host "Creating $appServiceName app service ..."
$functionApp = (az functionapp create --name $appServiceName --consumption-plan-location $azureLocation --resource-group $resourceGroupName --runtime $appServiceRuntime --storage-account $storageAccountName --os-type $osType --functions-version $functionsVersion | ConvertFrom-Json)

# Consumption plans are created automatically in the resource group, however, take a bit show up
$planName = $functionApp.serverfarmId.SubString($functionApp.serverFarmId.LastIndexOf("/") + 1)
$functionAppPlans = (az functionapp plan list --resource-group $resourceGroupName | ConvertFrom-Json)

Write-Host "Consumption based plans auto create and will sometimes take a bit to show up in the resource group, this loop will wait until it's available so the Slot creation doesn't fail ..."
while ($null -eq ($functionAppPlans | Where-Object {$_.Name -eq $planName}))
{
    Write-Host "Waiting 10 seconds for app plan $planName in $resourceGroupName to show up ..."
    Start-Sleep -Seconds 10
    $functionAppPlans = (az functionapp plan list --resource-group $resourceGroupName | ConvertFrom-Json)
}

Write-Host "It showed up!"

# Create deployment slots
Write-Host "Creating deployment slots ..."
az functionapp deployment slot create --resource-group $resourceGroupName --name $appServiceName --slot "staging"

Write-Host "Creating Octopus Azure Web App target for $appServiceName"
New-OctopusAzureWebAppTarget -Name $appServiceName -AzureWebApp $appServiceName -AzureResourceGroupName $resourceGroupName -OctopusAccountIdOrName $azureAccount -OctopusRoles "Octopub-Products-Function" -updateIfExisting