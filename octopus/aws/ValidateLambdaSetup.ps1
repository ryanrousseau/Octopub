# Define variables
$errorCollection = @()

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
    Write-Host "All checks succeeded!"
    Set-OctopusVariable -name "AwsLambdaConfigured" -value "True"
  }
}