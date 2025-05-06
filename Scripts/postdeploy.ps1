#!/usr/bin/env pwsh


$envValues = azd env get-values --output json | ConvertFrom-Json
$envConfig = Get-Content "./.azure/$($envValues.AZURE_ENV_NAME)/config.json" | ConvertFrom-Json
$funcName = $envConfig.infra.parameters.functionValues[0].name


$appSettings = az functionapp config appsettings list --name $funcName --resource-group $envValues.resourceGroupName | ConvertFrom-Json
$appSettingsHash = @{}
$appSettings | ForEach-Object { $appSettingsHash[$_.name] = $_.value }
#Write-Host $appSettings 

$localSettings = @{}
foreach ($key in $appSettingsHash.Keys) {
    $localSettings[$key] = $appSettingsHash[$key]
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
        $funcSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath "$path/local.settings.json"
        Write-Host "Created $path/local.settings.json for $(Split-Path $path -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "Directory $path not found. Skipping local.settings.json creation." -ForegroundColor Red
    }
}
