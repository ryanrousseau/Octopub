# Get variables
$resourceGroupName = "#{Project.Azure.ResourceGroup.Name}"
$appServicePlanName = "#{Project.Azure.WebApp.ServicePlan.Name}"
$skuCode = "#{Project.Azure.WebApp.ServicePlan.SKU}"

# Check to see if plan already exists
$appServicePlan = (((az appservice plan list --resource-group $resourceGroupName) | ConvertFrom-Json) | Where-Object {$_.name -eq "$appServicePlanName"})

if ($null -ne $appServicePlan)
{
    Write-Highlight "An App Service Plan with the name $appServicePlanName already exists."
}
else
{
    az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --sku $skuCode --is-linux
}