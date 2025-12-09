param()
$ErrorActionPreference = 'Stop'

function Get-DockerCreatedDate {
    param(
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [datetimeoffset]::MinValue
    }

    $normalized = $Value -replace '\s+[A-Z]{2,}$', ''
    try {
        return [datetimeoffset]::ParseExact($normalized, 'yyyy-MM-dd HH:mm:ss zzz', $null)
    }
    catch {
        Write-Warning "Unable to parse docker CreatedAt timestamp '$Value'."
        return [datetimeoffset]::MinValue
    }
}

Write-Host "Synchronizing container images to ACR..." -ForegroundColor DarkCyan

$envValues = azd env get-values --output json | ConvertFrom-Json
$envName = $envValues.AZURE_ENV_NAME
$appNameSafe = $envValues.APP_NAME_SAFE
$location = $envValues.AZURE_LOCATION

if (-not $envName) {
    throw "Unable to determine AZURE_ENV_NAME from azd environment."
}

$abbrs = Get-Content './infra/constants/abbreviations.json' -Raw | ConvertFrom-Json
$appNameLower = $appNameSafe.ToLower()
$locationLower = $location.ToLower()
$registryBase = ($abbrs.containerRegistry + $appNameLower + $locationLower).ToLower()
$containerRegistryName = if ($registryBase.Length -gt 50) { $registryBase.Substring(0, 50) } else { $registryBase }
$registryServer = "$containerRegistryName.azurecr.io"

Write-Host "Logging into registry $containerRegistryName" -ForegroundColor DarkCyan
az acr login -n $containerRegistryName | Out-Null

$azureYaml = Get-Content './azure.yaml' -Raw
$projectNameMatch = [regex]::Match($azureYaml, '^\s*name:\s*(?<name>\S+)\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
if (-not $projectNameMatch.Success) {
    throw "Unable to determine project name from azure.yaml."
}
$projectName = $projectNameMatch.Groups['name'].Value

$configPath = "./.azure/$envName/config.json"
if (-not (Test-Path $configPath)) {
    throw "Environment config file not found at $configPath."
}
$envConfig = Get-Content $configPath -Raw | ConvertFrom-Json
$functionValues = $envConfig.infra.parameters.functionValues
if (-not $functionValues) {
    Write-Host "No function values defined; skipping image sync." -ForegroundColor Yellow
    return
}

foreach ($function in $functionValues) {
    $serviceName = $function.serviceName.ToLower()
    $localRepo = "$projectName/$serviceName-$appNameLower"
    $imageMetadata = @(docker images $localRepo --format '{{json .}}' |
        ForEach-Object { $_ | ConvertFrom-Json } |
        Where-Object { $_.Tag -like 'azd-deploy-*' })
    if (-not $imageMetadata) {
        throw "Could not locate local azd-deploy image for  $($localRepo). Ensure azd package succeeded."
    }
    $latestImage = $imageMetadata |
        Sort-Object { (Get-DockerCreatedDate $_.CreatedAt).UtcDateTime } -Descending |
        Select-Object -First 1
    $tag = $latestImage.Tag
    $source = "$($localRepo):$tag"
    $targetRepo = "$registryServer/$serviceName"
    $target = "$($targetRepo):latest"
    Write-Host "Tagging $source => $target" -ForegroundColor Cyan
    docker tag $source $target
    Write-Host "Pushing $target" -ForegroundColor Gray
    docker push $target | Out-Null
}

Write-Host "Container images synced to $registryServer" -ForegroundColor Green
