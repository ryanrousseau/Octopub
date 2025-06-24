# Get variables
$resourceGroupName = $OctopusParameters['Project.Azure.ResourceGroup.Name']

$groupExists = az group exists --name $resourceGroupName

if($groupExists -eq $true) {
    Write-Host "Deleting Resource Group: $resourceGroupName"
    az group delete --name $resourceGroupName --yes
    Write-Highlight "Deleted Resource Group: $resourceGroupName"
}
else {
    Write-Highlight "Resource Group: $resourceGroupName doesn't exist."
}