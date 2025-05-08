$ErrorActionPreference = 'Stop'

$functionName = "#{Project.AWS.Lambda.FunctionName}" 
$functionRole = "#{Project.AWS.Lambda.FunctionRole}" 
$functionRuntime = "#{Project.AWS.Lambda.Runtime}" 
$functionHandler = "#{Project.AWS.Lambda.FunctionHandler}" 
$functionMemorySize = "#{Project.AWS.Lambda.MemorySize}"
$functionVersionNumber = "#{Octopus.Action.Package[products-microservice-lambda-jvm].PackageVersion}"
$packageFilePath = "#{Octopus.Action.Package[products-microservice-lambda-jvm].PackageFilePath}"

$regionName = "#{Project.AWS.Region}" 
$stepName = "#{Octopus.Step.Name}"

# Bucket details
$bucketName = "#{Project.AWS.Lambda.S3.BucketName}"
$regionName = "#{Project.AWS.Region}" 

if ([string]::IsNullOrWhiteSpace($functionName)) {
    Write-Error "The parameter Function Name is required."
    Exit 1
}

if ([string]::IsNullOrWhiteSpace($functionRole)) {
    Write-Error "The parameter Role is required."
    Exit 1
}

if ([string]::IsNullOrWhiteSpace($functionRunTime)) {
    Write-Error "The parameter Run Time is required."
    Exit 1
}

if ([string]::IsNullOrWhiteSpace($functionHandler)) {
    Write-Error "The parameter Handler is required."
    Exit 1
}

Write-Output "Function Name: $functionName"
Write-Output "Function Role: $functionRole"
Write-Output "Function Runtime: $functionRuntime"
Write-Output "Function Handler: $functionHandler"
Write-Output "Function Memory Size: $functionMemorySize"
Write-Output "Function file path: $packageFilePath"
Write-Output "Function S3 Bucket: $bucketName"
Write-Output "AWS Region: $regionName"

Write-Output "##octopus[stdout-verbose]"

# Check if the bucket exists
$bucketExists = aws s3api head-bucket --region $regionName --bucket $bucketName 2>$null

Write-Output "##octopus[stdout-default]"

if ($LASTEXITCODE -eq 0) {
    Write-Output "Bucket '$bucketName' already exists."
}
else {
    Write-Output "Bucket '$bucketName' does not exist. Creating in region '$regionName'..."

    if ($regionName -ieq "us-east-1") {
        # us-east-1 does not require LocationConstraint
        aws s3api create-bucket --bucket $bucketName --region $regionName
    }
    else {
        # Other regions require LocationConstraint
        aws s3api create-bucket --bucket $bucketName --region $regionName `
            --create-bucket-configuration LocationConstraint=$regionName
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Output "Bucket '$bucketName' created successfully in region '$regionName'."
    }
    else {
        Write-Output "Failed to create bucket '$bucketName'."
    }
}

# Get the file name, no extension
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($packageFilePath)  
# S3 object key
$key = "$fileName.$functionVersionNumber.zip"
Copy-Item -Path $packageFilePath -Destination $key

if (-not (Test-Path $key)) {
    Write-Error "File '$key' not found."
    exit 1
}

# Check if the object already exists in the bucket
$objectExists = aws s3api head-object --bucket $bucketName --key $key --region $regionName 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Output "Object '$key' already exists in bucket '$bucketName'. Skipping upload."
}
else {
    Write-Output "Uploading new object to bucket '$bucketName'..."

    # Upload the file
    aws s3 cp $packageFilePath "s3://$bucketName/$key" --region $regionName

    if ($LASTEXITCODE -eq 0) {
        Write-Output "File uploaded successfully."
    }
    else {
        Write-Error "File upload failed."
    }
}

Write-Output "Attempting to find the function $functionName in the region $regionName"
Write-Output "##octopus[stderr-progress]"

aws lambda get-function --function-name $functionName --region $regionName | Out-Null
$exitCode = $LASTEXITCODE

Write-Output "##octopus[stderr-default]"

if ($exitCode -eq 0) {
    Write-Highlight "Lambda function '$functionName' exists. Updating code from S3..."

    $lambdaFunction = aws lambda update-function-code `
        --function-name $functionName `
        --s3-bucket $bucketName `
        --s3-key $key `
        --region $regionName 

    if ($LASTEXITCODE -eq 0) {
        Write-Highlight "Lambda function '$functionName' updated successfully."
    }
    else {
        Write-Error "Failed to update Lambda function."
    }

    Write-Output "Waiting for update to complete ..."
    aws lambda wait function-updated `
        --function-name "$functionName" `
        --region $regionName
    
    Write-Highlight "Updating the $functionName base configuration"    
    aws lambda update-function-configuration `
        --function-name "$functionName" `
        --role $functionRole `
        --handler $functionHandler `
        --runtime $functionRuntime `
        --memory-size $functionMemorySize `
        --region $regionName `
        | Out-Null
    
    Write-Output "Waiting for base configuration update to complete ..."
    aws lambda wait function-updated `
        --function-name "$functionName" `
        --region $regionName

}
else {
    Write-Highlight "Creating new Lambda function '$functionName' from S3..."
    $lambdaFunction = aws lambda create-function `
        --function-name $functionName `
        --runtime $functionRuntime `
        --role $functionRole `
        --handler $functionHandler `
        --code S3Bucket=$bucketName,S3Key=$key `
        --region $regionName `
        --timeout 10 `
        --memory-size $functionMemorySize 

    if ($LASTEXITCODE -eq 0) {
        Write-Highlight "Lambda function '$functionName' created successfully."
    }
    else {
        Write-Error "Failed to create Lambda function."
    }

    Write-Output "Waiting for new function to complete updating..."
    aws lambda wait function-updated `
        --function-name "$functionName" `
        --region $regionName
}
Write-Verbose "$lambdaFunction"

$functionInformation = $lambdaFunction | ConvertFrom-JSON
$functionArn = $functionInformation.FunctionArn

Write-Output "Function ARN: $functionArn"

Write-Highlight "Publishing the function with the description $functionVersionNumber to create a snapshot of the current code and configuration of this function in AWS."
$publishedVersion = aws lambda publish-version `
    --function-name "$functionArn" `
    --description "$functionVersionNumber"
    
$publishedVersion = $publishedVersion | ConvertFrom-JSON
    
Write-Highlight "Setting the output variable 'Octopus.Action[$($stepName)].Output.PublishedVersion' to $($publishedVersion.Version)"
Set-OctopusVariable -name "PublishedVersion" -value "$($publishedVersion.Version)"    

Write-Highlight "Setting the output variable 'Octopus.Action[$($stepName)].Output.LambdaArn' to $functionArn"
Set-OctopusVariable -name "LambdaArn" -value "$functionArn"

Write-Highlight "AWS Lambda $functionName successfully deployed."