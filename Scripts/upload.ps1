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
    $abbrs = Get-Content './infra/constants/abbreviations.json' | ConvertFrom-Json
    $envValues = azd env get-values --output json | ConvertFrom-Json
    $appNameSafe = $envValues.APP_NAME_SAFE
    $location = $envValues.AZURE_LOCATION
    $appNameLower = $appNameSafe.ToLower()
    $formStorageBase = "{0}{1}{2}" -f $abbrs.storageAccount, $appNameLower, $location
    if($formStorageBase.Length -gt 24) {
        $formStorageBase = $formStorageBase.Substring(0,24)
    }

    $storageAccountName = $formStorageBase
    $containerName = 'documents'

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



