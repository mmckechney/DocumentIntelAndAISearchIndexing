#!/usr/bin/env pwsh

$abbrs = Get-Content './infra/constants/abbreviations.json' | ConvertFrom-Json
$envValues = azd env get-values --output json | ConvertFrom-Json
$envName = $envValues.AZURE_ENV_NAME
if (-not $envName) {
    Write-Error "AZURE_ENV_NAME is not set. Run azd env select or scripts/preup.ps1 first."
    exit 1
}

$envConfigPath = "./.azure/$envName/config.json"
if (-not (Test-Path $envConfigPath)) {
    Write-Error "Environment config not found at $envConfigPath. Run scripts/preup.ps1 first."
    exit 1
}

$envConfig = Get-Content $envConfigPath | ConvertFrom-Json
$functionValues = $envConfig.infra.parameters.functionValues
if (-not $functionValues -or $functionValues.Count -eq 0) {
    Write-Error "No container apps were found in config file."
    exit 1
}

$resourceGroupName = $envValues.AZURE_RESOURCE_GROUP
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    $resourceGroupName = "{0}{1}" -f $abbrs.resourceGroup, $envValues.APP_NAME
}

$primaryContainerAppName = $functionValues[0].name
Write-Host "Fetching environment variables from container app '$primaryContainerAppName' in '$resourceGroupName'" -ForegroundColor DarkCyan
$containerApp = az containerapp show --name $primaryContainerAppName --resource-group $resourceGroupName | ConvertFrom-Json

if (-not $containerApp) {
    Write-Error "Failed to retrieve container app '$primaryContainerAppName'. Ensure it has been provisioned by azd up."
    exit 1
}

$localSettings = @{}
foreach ($container in $containerApp.properties.template.containers) {
    foreach ($envVar in $container.env) {
        if ($null -ne $envVar.value -and -not [string]::IsNullOrWhiteSpace($envVar.value)) {
            $localSettings[$envVar.name] = $envVar.value
        }
    }
}

if ($localSettings.Count -eq 0) {
    Write-Warning "No environment variables were discovered on container app '$primaryContainerAppName'."
}

$funcSettings = @{
    "IsEncrypted" = $false
    "Values" = $localSettings
}

$functionPaths = @(
    "./src/CustomFieldExtractionFunction",
    "./src/DocumentIntelligenceFunction",
    "./src/ProcessedFileMover",
    "./src/DocumentQueueingFunction",
    "./src/AiSearchIndexingFunction",
    "./src/DocumentQuestionsFunction"
)

foreach ($path in $functionPaths) {
    if (Test-Path $path) {
        # Save local settings to file
        $localSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath "$path/local.settings.json"
        Write-Host "Created $path/local.settings.json for $(Split-Path $path -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "Directory $path not found. Skipping local.settings.json creation." -ForegroundColor Red
    }
}
