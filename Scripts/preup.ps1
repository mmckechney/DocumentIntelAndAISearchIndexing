# Get the current user's object ID
Write-Host "Getting current user object id" -ForegroundColor DarkCyan
$user = az ad signed-in-user show | ConvertFrom-Json
if (-not $user) {
    Write-Error "Failed to get current user object ID. Make sure you're logged into Azure CLI."
    exit 1
}
$currentUserObjectId = $user.id
$userName = $user.displayName
$userEmail = $user.mail
Write-Host "Current User Object Id: $currentUserObjectId" -ForegroundColor Green

Write-Host "Getting public IP" -ForegroundColor DarkCyan
$myPublicIp = (Invoke-WebRequest https://api.ipify.org?format=text).Content.Trim()
if (-not $myPublicIp) {
    Write-Error "Failed to get current Public IP. This is required for the deployment."
    exit 1
}
Write-Host "Public IP: $myPublicIp" -ForegroundColor Green


$abbrs = Get-Content './infra/constants/abbreviations.json' | ConvertFrom-Json

$envValues = azd env get-values --output json | ConvertFrom-Json
$envName = $envValues.AZURE_ENV_NAME
$location = $envValues.AZURE_LOCATION
$safeEnvName = $envName -replace '[^a-zA-Z0-9]', ''

$functionValues = @(
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-customfield"
        tag  = "custom-field-function"
        serviceName = "custom-field-app"
    },
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-intelligence"
        tag  = "intelligence-function"
        serviceName = "intelligence-app"
    },
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-mover"
        tag  = "mover-function"
        serviceName = "mover-app"
    },
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-queueing"
        tag  = "queueing-function"
        serviceName = "queueing-app"
    },
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-aisearch"
        tag  = "aisearch-function"
        serviceName = "aisearch-app"
    },
    @{
        name = "$($abbrs.containerApp)$($safeEnvName)-askquestions"
        tag  = "askquestions-function"
        serviceName = "askquestions-app"
    }
)

# Update the 'functionValues' parameter in ../infra/main.parameters.json
$mainParamsPath = Join-Path $PSScriptRoot "../infra/main.parameters.json"
$mainParamsContent = Get-Content $mainParamsPath -Raw | ConvertFrom-Json

$foundryConfig = $mainParamsContent.parameters.foundryConfig.value

if ($null -ne $foundryConfig.accountName) {
    $foundryConfig.accountName = $foundryConfig.accountName -replace '\$\{APP_NAME_SAFE\}', $safeEnvName
}
if ($null -ne $foundryConfig.projectName) {
    $foundryConfig.projectName = $foundryConfig.projectName -replace '\$\{APP_NAME_SAFE\}', $safeEnvName
}
if ($null -ne $foundryConfig.projectDisplayName) {
    $foundryConfig.projectDisplayName = $foundryConfig.projectDisplayName -replace '\$\{APP_NAME\}', $envName
}

$foundryAgentIdValue = $mainParamsContent.parameters.foundryAgentId.value
if ($foundryAgentIdValue -match '\$\{AZURE_FOUNDRY_AGENT_ID\}' -and $envValues.AZURE_FOUNDRY_AGENT_ID) {
    $foundryAgentIdValue = $envValues.AZURE_FOUNDRY_AGENT_ID
}

$configObject = @{
        infra = @{
            parameters = @{
                docIntelligenceInstanceCount = 2
                functionValues = $functionValues
                foundryConfig = $foundryConfig
                foundryAgentId = $foundryAgentIdValue
            }
        }
    }
$envConfigPath = Join-Path $PSScriptRoot "../.azure/${envName}/config.json"
$configObject | ConvertTo-Json -Depth 10 | Set-Content -Path $envConfigPath -Encoding utf8
Write-Host "Updated $envConfigPath successfully." -ForegroundColor Green

# Path to .env file
$envFilePath = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
$envContent = @()

# Function to set environment variables in both azd and .env file
function Set-EnvironmentVariable {
    param (
        [string]$Name,
        [string]$Value
    )
    
    # Set in azd environment
    Write-Host "Setting $Name to $Value"
    azd env set $Name $Value
    
    # Add to .env content
    $envContent += "$Name=$Value"
}

# Set the user object ID as an environment variable for the deployment
#Set-EnvironmentVariable -Name "AZURE_RESOURCE_GROUP" -Value $resourceGroupName
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_OBJECT_ID" -Value $currentUserObjectId
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_NAME" -Value $userName
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_EMAIL" -Value $userEmail
Set-EnvironmentVariable -Name "PUBLIC_IP" -Value $myPublicIp
Set-EnvironmentVariable -Name "APP_NAME" -Value $envName
Set-EnvironmentVariable -Name "APP_NAME_SAFE" -Value $safeEnvName
Set-EnvironmentVariable -Name "AZURE_CONTAINER_REGISTRY_ENDPOINT" -Value "$($abbrs.containerRegistry)$($safeEnvName)$($location).azurecr.io"

# Write all environment variables to .env file
Write-Host "Writing environment variables to .env file at $envFilePath"
$envContent | Out-File -FilePath $envFilePath -Encoding utf8 -Force
Write-Host ".env file created/updated successfully."