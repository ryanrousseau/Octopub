$appServiceName = "#{Project.Azure.Function.Octopub.Products.Name}"
$apiKey = "#{Project.Octopus.Api.Key}"
$spaceId = "#{Octopus.Space.Id}"
$headers = @{"X-Octopus-ApiKey"=$apiKey}

if ([String]::IsNullOrWhitespace("#{Octopus.Web.ServerUri}"))
{
    $octopusUrl = "#{Octopus.Web.BaseUrl}"
}
else
{
    $octopusUrl = "#{Octopus.Web.ServerUri}"
}

$uriBuilder = New-Object System.UriBuilder("$octopusUrl/api/$spaceId/machines")
$query = [System.Web.HttpUtility]::ParseQueryString("")
$query["name"] = $appServiceName
$query["environmentIds"] = "#{Octopus.Environment.Id}"
$uriBuilder.Query = $query.ToString()
$uri = $uriBuilder.ToString()

$octopubTarget = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

foreach ($target in $octopubTarget.Items)
{
    if ($target.Name -eq $appServiceName)
    {
        Write-Host "Deregistering" + $target.Name
        $uri = "$octopusUrl/api/$spaceId/machines/$($target.Id)"
        Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
    }
}