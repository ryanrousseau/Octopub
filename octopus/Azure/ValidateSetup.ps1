# Define parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$Role,
    [Parameter(Mandatory=$true)]
    [bool]$CheckForTargets
)

# Define variables
$errorCollection = @()
$setupValid = $false

try
{
  $azureConfigured = $true

  # Ensure Azure account is configured
  Write-Host "Verifying Azure Account has been configured ..."

  # Check the Azure Account properties
  if ("#{Project.Azure.Account.SubscriptionNumber}" -eq "00000000-0000-0000-0000-000000000000")
  {
    # Add to error messages
    $errorCollection += @("The Azure Account Subscription Number has not been configured.")
    $azureConfigured = $false
  }

  if ("#{Project.Azure.Account.Client}" -eq "00000000-0000-0000-0000-000000000000")
  {
    # Add to error messages
    $errorCollection += @("The Azure Account Client Id has not been configured.")
    $azureConfigured = $false
  }

  if ("#{Project.Azure.Account.TenantId}" -eq "00000000-0000-0000-0000-000000000000")
  {
    # Add to error messages
    $errorCollection += @("The Azure Account Tenant Id has not been configured.")
    $azureConfigured = $false
  }

  if ("#{Project.Azure.Account.Password}" -eq "CHANGE ME")
  {
    # Add to error messages
    $errorCollection += @("The Azure Account Password has not been configured.")
    $azureConfigured = $false
  }

  if (-not $azureConfigured) {
    $errorCollection += @("See the [documentation](https://octopus.com/docs/infrastructure/accounts/azure#azure-service-principal) for details on configuring an Azure Service Principal")
  }

  Write-Host "Checking to see if Project variables have been configured ..."

  if ("#{Project.Octopus.Api.Key}" -eq "CHANGE ME")
  {
    $errorCollection += @(
      "The project variable Project.Octopus.Api.Key has not been configured.",
      "See the [Octopus documentation](https://octopus.com/docs/octopus-rest-api/how-to-create-an-api-key) for details on creating an API key."
    )
  }

  if ($CheckForTargets)
  {
    Write-Host "Checking for deployment targets ..."

    # Check to make sure targets have been created
    if ([string]::IsNullOrWhitespace("#{Octopus.Web.ServerUri}"))
    {
      $octopusUrl = "#{Octopus.Web.BaseUrl}"
    }
    else
    {
      $octopusUrl = "#{Octopus.Web.ServerUri}"
    }

    $apiKey = "#{Project.Octopus.Api.Key}"
    if (![string]::IsNullOrWhitespace($apiKey) -and $apiKey -ne "CHANGE ME")
    {
      $spaceId = "#{Octopus.Space.Id}"
      $headers = @{"X-Octopus-ApiKey"="$apiKey"}

      $roleTargets = Invoke-RestMethod -Method Get -Uri "$octopusUrl/api/$spaceId/machines?roles=$Role" -Headers $headers
      
      if ($roleTargets.Items.Count -lt 1)
      {
        $errorCollection += @("Expected at least 1 target for role $Role, but found $($roleTargets.Items.Count).  Have you run the Create Infrastructure runbook?")
      }
    }
  }

  if ($errorCollection.Count -gt 0)
  {
    Write-Host "The project setup could not be validated.  Please check the following errors:"
    Write-Host "-----------------------------------------------------"
    foreach ($item in $errorCollection)
    {
      Write-Highlight "$item"
    }
  }
  else
  {
    $setupValid = $true
    Write-Host "Setup valid!"
  }

  Set-OctopusVariable -Name SetupValid -Value $setupValid  

}
catch
{
  Write-Verbose "Fatal error occurred:"
  Write-Verbose "$($_.Exception.Message)"
}
