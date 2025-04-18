param(
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName

)


$functionApps = az functionapp list --resource-group $resourceGroupName --query "[].name" -o tsv

foreach($functionAppName in $functionApps)
{
    # Check if the function app is properly configured for Linux
    Write-Host "Checking Linux configuration for $functionAppName in $resourceGroupName" -ForegroundColor Cyan

    # Get the function app details
    $functionApp = az functionapp show -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
    Write-Host "Function app OS: $($functionApp.kind)" -ForegroundColor Yellow

    # Check if the function app is configured for Linux
    if ($functionApp.kind -notlike "*linux*") {
        Write-Host "Function app is not configured for Linux" -ForegroundColor Red
        exit 1
    }
    
        else {
            Write-Host "Function app is configured for Linux" -ForegroundColor Green
        }

    # Check the Linux runtime configuration
    $linuxFxVersion = az functionapp config show -g $resourceGroupName -n $functionAppName --query linuxFxVersion -o tsv
    Write-Host "Linux runtime configuration: $linuxFxVersion" -ForegroundColor Yellow

    # Check if the function app has the correct runtime configuration
    if ($linuxFxVersion -notlike "DOTNET-ISOLATED|*") {
        Write-Host "Function app runtime is not configured for .NET isolated" -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "Function app runtime is configured for .NET isolated" -ForegroundColor Green
    }

    # Check the function app settings
    $settings = az functionapp config appsettings list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json

    # Check if the function app has the required settings for Linux
    $requiredSettings = @(
        "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING",
        "AzureWebJobsStorage",
        "FUNCTIONS_WORKER_RUNTIME",
        "WEBSITE_RUN_FROM_PACKAGE"
    )

    $missingSettings = @()
    foreach ($setting in $requiredSettings) {
        if (-not ($settings | Where-Object { $_.name -eq $setting })) {
            $missingSettings += $setting
        }
    }

    if ($missingSettings.Count -gt 0) {
        Write-Host "Function app is missing required settings: $($missingSettings -join ', ')" -ForegroundColor Red
        exit 1
    }else 
    {
        Write-Host "Function app has all required settings" -ForegroundColor Green
    }

    # Check worker runtime setting
    $workerRuntime = ($settings | Where-Object { $_.name -eq "FUNCTIONS_WORKER_RUNTIME" }).value
    if ($workerRuntime -ne "dotnet-isolated") {
        Write-Host "Function app worker runtime is not set to dotnet-isolated" -ForegroundColor Red
        exit 1
    }else
    {
        Write-Host "Function app worker runtime is set to dotnet-isolated" -ForegroundColor Green
    }

    # Get the function app's functions
    $functions = az functionapp function list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
    if ($functions.Count -eq 0) {
        Write-Host "Function app has no functions - this could indicate a deployment issue" -ForegroundColor Red
    }
    else {
        Write-Host "Function app has $($functions.Count) functions:" -ForegroundColor Green
        $functions | ForEach-Object {
            Write-Host "- $($_.name)" -ForegroundColor Green
        }
    }

    Write-Host "Function app $functionAppName appears to be properly configured for Linux" -ForegroundColor Green
}