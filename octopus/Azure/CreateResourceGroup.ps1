# Get variables
$resourceGroupName = $OctopusParameters['Project.Azure.ResourceGroup.Name']
$azureLocation = $OctopusParameters['Project.Azure.Location']
$resourceGroupCreated = $false

# Check to see if the group already exists
$groupExists = az group exists --name $resourceGroupName

if ($groupExists -eq $true)
{
    Write-Highlight "A Resource Group with the name of $resourceGroupName already exists.  We recommend creating a new Resource Group for this example."
}
else
{
    # Create resourece group
    Write-Host "Creating resource group $resourceGroupName in $azureLocation..."
    az group create --location $azureLocation --name $resourceGroupName

    $resourceGroupCreated = $true
}

# Set output variable
Set-OctopusVariable -Name "ResourceGroupCreated" -Value $resourceGroupCreated