param(
    [Parameter(Mandatory=$true)]
    [string] $resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string] $functionAppName
)

Write-Host "Checking status of function app: $functionAppName" -ForegroundColor Cyan
$status = az functionapp show -g $resourceGroupName -n $functionAppName --query state -o tsv
Write-Host "Function app status: $status" -ForegroundColor Yellow

Write-Host "Getting function app settings..." -ForegroundColor Cyan
$settings = az functionapp config appsettings list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
Write-Host "Function app settings:" -ForegroundColor Yellow
$settings | Format-Table name, value -AutoSize

Write-Host "Checking function app logs..." -ForegroundColor Cyan
$logs = az functionapp log tail -g $resourceGroupName -n $functionAppName
Write-Host "Function app logs:" -ForegroundColor Yellow
$logs

Write-Host "Verifying Linux runtime configuration..." -ForegroundColor Cyan
$config = az functionapp config show -g $resourceGroupName -n $functionAppName --query linuxFxVersion -o tsv
Write-Host "Linux runtime configuration: $config" -ForegroundColor Yellow

Write-Host "Checking function app functions..." -ForegroundColor Cyan
$functions = az functionapp function list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
Write-Host "Function app functions:" -ForegroundColor Yellow
$functions | Format-Table name, isDisabled -AutoSize

Write-Host "Checking deployment history..." -ForegroundColor Cyan
$deployments = az webapp deployment list -g $resourceGroupName -n $functionAppName | ConvertFrom-Json
Write-Host "Deployment history:" -ForegroundColor Yellow
$deployments | Format-Table id, status, author, deployer, message -AutoSize

Write-Host "Restarting function app..." -ForegroundColor Cyan
az functionapp restart -g $resourceGroupName -n $functionAppName
Write-Host "Function app restarted" -ForegroundColor Green
