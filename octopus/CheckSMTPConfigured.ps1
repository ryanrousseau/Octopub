# Get Octopus Variables
$apiKey = "#{Project.Octopus.Api.Key}"
$isSmtpConfigured = $false

# Check to see if API key has 
if (![string]::IsNullOrWhitespace($apiKey) -and $apiKey -ne "CHANGE ME")
{
  if ([String]::IsNullOrWhitespace("#{Octopus.Web.ServerUri}"))
  {
    $octopusUrl = "#{Octopus.Web.BaseUrl}"
  }
  else
  {
    $octopusUrl = "#{Octopus.Web.ServerUri}"
  }    

  $uriBuilder = New-Object System.UriBuilder("$octopusUrl/api/smtpconfiguration/isconfigured")
  $uri = $uriBuilder.ToString()

  try
  {
    $headers = @{ "X-Octopus-ApiKey" = $apiKey }
    $smtpConfigured = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    $isSmtpConfigured = $smtpConfigured.IsConfigured
  }
  catch
  {
    Write-Host "Error checking SMTP configuration: $($_.Exception.Message)"
  }
}
else 
{
    Write-Highlight "The project variable Project.Octopus.Api.Key has not been configured, unable to check SMTP configuration."
}

if (-not $isSmtpConfigured)
{
    Write-Highlight "SMTP is not configured. Please [configure SMTP](https://octopus.com/docs/projects/built-in-step-templates/email-notifications#smtp-configuration) settings in Octopus Deploy."
}

# Set output variable
Set-OctopusVariable -Name SmtpConfigured -Value $isSmtpConfigured