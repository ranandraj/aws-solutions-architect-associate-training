# Remove AWS CLI configuration and credentials

$AwsDir = Join-Path $env:USERPROFILE ".aws"

Write-Host "AWS configuration directory: $AwsDir"

if (Test-Path $AwsDir) {
    Remove-Item $AwsDir -Recurse -Force
    Write-Host "AWS CLI configuration removed successfully."
} else {
    Write-Host "AWS CLI configuration directory does not exist."
}

# Remove AWS-related environment variables from the current PowerShell session

$AwsEnvVars = @(
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "AWS_SESSION_TOKEN",
    "AWS_PROFILE",
    "AWS_DEFAULT_REGION",
    "AWS_REGION",
    "AWS_CONFIG_FILE",
    "AWS_SHARED_CREDENTIALS_FILE"
)

foreach ($Var in $AwsEnvVars) {
    if (Test-Path "Env:\$Var") {
        Remove-Item "Env:\$Var" -ErrorAction SilentlyContinue
        Write-Host "Removed environment variable: $Var"
    }
}

Write-Host ""
Write-Host "Testing AWS credentials..."

aws sts get-caller-identity