# Get variables
$storageAccountName = $OctopusParameters['Project.Azure.StorageAccount.Name']
$resourceGroupName = $OctopusParameters['Project.Azure.ResourceGroup.Name']
$azureLocation = $OctopusParameters['Project.Azure.Location']
$storageAccountCreated = $false

# Check to see if name is already being used in this subscription
$accountExists = ((az storage account check-name --name $storageAccountName) | ConvertFrom-Json)

if ($accountExists.nameAvailable -ne $true)
{
    Write-Highlight "A storage account with the name $storageAccountName already exists in your subscription.  Please update the Project Variable Project.Azure.StorageAccount.Name"
}
else
{
    # Create Azure storage account
    Write-Host "Creating storage account ..."
    az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $azureLocation

    $storageAccountCreated = $true
}

Set-OctopusVariable -Name StorageAccountCreated -Value  $storageAccountCreated
# Get account keys
$accountKeys = (az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName) | ConvertFrom-JSON