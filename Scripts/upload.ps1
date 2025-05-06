param(
    [string]$file = "C:\Users\mimcke\OneDrive\source\ShippingSampleDocs\BILL OF LADING.docx"
)

#get just the file name from the path
if($file -eq "" )
{
    Write-Host "Please provide a file name to upload."
    exit 1
}
else 
{
    $fileObj = Get-Item $file
    if($null -eq $fileObj )
    {
        Write-Host "File '$file' not found."
        exit 1
    }
}

$containerName = $env:UPLOAD_SCRIPT_CONTAINER_NAME
$storageAccountName = $env:UPLOAD_SCRIPT_STORAGE_ACCOUNT_NAME

if($null -eq $containerName -or $null -eq $storageAccountName )
{
    $envValues = azd env get-values --output json | ConvertFrom-Json
    $envConfig = Get-Content "./.azure/$($envValues.AZURE_ENV_NAME)/config.json" | ConvertFrom-Json
    $funcName = $envConfig.infra.parameters.functionValues[0].name
    $appSettings = az functionapp config appsettings list --name $funcName --resource-group $envValues.resourceGroupName | ConvertFrom-Json
    $appSettingsHash = @{}
    $appSettings | ForEach-Object { $appSettingsHash[$_.name] = $_.value }

    $containerName = $appSettingsHash["STORAGE_SOURCE_CONTAINER_NAME"]
    $storageAccountName = $appSettingsHash["STORAGE_ACCOUNT_NAME"]

    $env:UPLOAD_SCRIPT_CONTAINER_NAME = $containerName
    $env:UPLOAD_SCRIPT_STORAGE_ACCOUNT_NAME = $storageAccountName
}

if("true" -eq (az storage blob exists  --name "$($fileObj.Name)" --container-name $containerName -n $fileObj.Name --auth-mode login --account-name $storageAccountName --query exists -o tsv) )
{
    Write-Output "Skipping $file'. It already exists in the container '$containerName'"
}
else 
{
    Write-Output "Uploading '$file' to container '$containerName'"
    #output this command to the console
    Write-Output "az storage blob upload -f '$($fileObj.FullName)' -c $containerName -n '$($fileObj.Name)' --account-name $storageAccountName --auth-mode login -o tsv"
    az storage blob upload -f "$($fileObj.FullName)" -c $containerName -n $fileObj.Name --account-name $storageAccountName --auth-mode login -o tsv
}



