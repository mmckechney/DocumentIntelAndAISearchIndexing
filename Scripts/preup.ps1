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
$location= $envValues.AZURE_LOCATION
$envName = $envValues.AZURE_ENV_NAME
$safeEnvName = $envName -replace '[^a-zA-Z0-9]', ''
#$resourceGroupName = "$($abbrs.resourceGroup)$($safeEnvName)"




$functionValues = @(
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-CustomField"
        tag  = "custom-field-function"
    },
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-Intelligence"
        tag  = "intelligence-function"
    },
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-Mover"
        tag  = "mover-function"
    },
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-Queueing"
        tag  = "queueing-function"
    },
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-AiSearch"
        tag  = "aisearch-function"
    },
    @{
        name = "$($abbrs.functionApp)$($safeEnvName)-AskQuestions"
        tag  = "askquestions-function"
    }
)

# Update the 'functionValues' parameter in ../infra/main.parameters.json with the JSON array of $functionNames
$mainParamsPath = Join-Path $PSScriptRoot "../infra/main.parameters.json"
$mainParamsContent = Get-Content $mainParamsPath -Raw | ConvertFrom-Json

# Convert $functionNames to JSON array
$functionValuesJson = $functionValues | ConvertTo-Json -Depth 10
$openAiConfigs = $mainParamsContent.parameters.openAiConfigs.value
foreach ($cfg in $openAiConfigs.configs) {
    if($null -eq $cfg.name -or $cfg.name -eq "") {
        $cfg.name = "$($safeEnvName)-$($cfg.suffix)"
    }
}

$configObject = @{
        infra = @{
            parameters = @{
                docIntelligenceInstanceCount = 2
                functionValues = $functionValues
                openAiConfigs = $openAiConfigs
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

$funcString = ($functionNames | ConvertTo-Json -Depth 10) -replace '\r\n ', '' -replace '\"', '"'
# Set the user object ID as an environment variable for the deployment
#Set-EnvironmentVariable -Name "AZURE_RESOURCE_GROUP" -Value $resourceGroupName
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_OBJECT_ID" -Value $currentUserObjectId
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_NAME" -Value $userName
Set-EnvironmentVariable -Name "AZURE_CURRENT_USER_EMAIL" -Value $userEmail
Set-EnvironmentVariable -Name "PUBLIC_IP" -Value $myPublicIp
Set-EnvironmentVariable -Name "APP_NAME" -Value $safeEnvName


# Write all environment variables to .env file
Write-Host "Writing environment variables to .env file at $envFilePath"
$envContent | Out-File -FilePath $envFilePath -Encoding utf8 -Force
Write-Host ".env file created/updated successfully."