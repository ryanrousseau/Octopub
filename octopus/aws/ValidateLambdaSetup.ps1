# Define variables
$errorCollection = @()
$apiKey = "#{Project.Octopus.Api.Key}"
$isSmtpConfigured = $false

# Check 1, ensure AWS account is configured
try
{
  $awsConfigured = $true

  # Ensure AWS account is configured
  Write-Output "Verifying AWS Account has been configured ..."

  if ("#{Octopus.Step[Attempt Login].Status.Code}" -ne "Succeeded") {
    $errorCollection += @("The previous step failed, which indicates the AWS Account is not valid.")
    $awsConfigured = $false
  }

  if (-not $awsConfigured) {
    $errorCollection += @("We recommend using an [AWS OIDC Account](https://octopus.com/docs/infrastructure/accounts/aws#configuring-aws-oidc-account) type to authenticate with AWS.")
  }

  Write-Output "Checking to see if Project variables have been configured ..."

  if ([string]::IsNullOrWhitespace("#{Project.AWS.Region}"))
  {
    $errorCollection += @(
      "The project variable Project.AWS.Region has not been configured.",
      "See the [AWS documentation](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/lambda/create-function.html#options) for details on region."
    )
  }

  if ([string]::IsNullOrWhitespace("#{Project.AWS.Lambda.FunctionName}"))
  {
    $errorCollection += @(
      "The project variable Project.AWS.Lambda.FunctionName has not been configured.",
      "See the [AWS documentation](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/lambda/create-function.html#options) for details on function name."
    )
  }

  if ([string]::IsNullOrWhitespace("#{Project.AWS.Lambda.S3.BucketName}"))
  {
    $errorCollection += @(
      "The project variable Project.AWS.Lambda.S3.BucketName has not been configured.",
      "See the [AWS documentation](https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-zip.html#configuration-function-update) for details on storing your function code in an S3 bucket."
    )
  }

}
catch
{
  Write-Verbose "Fatal error occurred:"
  Write-Verbose "$($_.Exception.Message)"
}
finally
{
  # Check to see if any errors were recorded
  if ($errorCollection.Count -gt 0)
  {
    # Display the messages
    Write-Highlight "$($errorCollection -join "`n")"

    # Set output variable to skip Lambda deployment using variable run condition
    Set-OctopusVariable -name "AwsLambdaConfigured" -value "False"

  }
  else
  {
    Write-Host "All AWS checks succeeded!"
    Set-OctopusVariable -name "AwsLambdaConfigured" -value "True"
  }
}

# 2. check SMTP configuration
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

Set-OctopusVariable -Name SmtpConfigured -Value $isSmtpConfigured