param
(
    [Parameter(Mandatory=$true)]
    [string] $storageAccountName,
    [Parameter(Mandatory=$true)]
    [string] $containerName,
    [Parameter(Mandatory=$true)]
    [string] $path = "",
    [int] $counterStart = 0,
    [int] $duplicateCount = 100
)

$counterEnd = $counterStart + $duplicateCount

if($path -ne "" )
{
    $files = Get-ChildItem -Path $path –File
    foreach($file in $files)
    {
        if("true" -eq (az storage blob exists  --name "$($file.Name)" --container-name $containerName -n $file.Name --auth-mode login --account-name $storageAccountName --query exists -o tsv) )
        {
            Write-Output "Skipping $file'. It already exists in the container '$containerName'"
        }
        else 
        {
            Write-Output "Uploading '$file' to container '$containerName'"
            az storage blob upload -f "$($file.FullName)" -c $containerName -n $file.Name --account-name $storageAccountName --auth-mode login -o tsv
        }
    }
}

$list = az storage blob list --container-name $containerName --account-name $storageAccountName --auth-mode login  --query [].name
$files = $list | ConvertFrom-Json

$counterEnd = $counterStart + $duplicateCount
for($i = $counterStart ; $i -lt $counterEnd; $i++) 
{
    foreach($file in $files)
    {
        $dest = $($i.ToString().PadLeft(6, "0") + "-" + $file)
        Write-Output "Copying '$file' to '$dest'"
        az storage blob copy start --source-blob "$file" --source-container $containerName --destination-blob "$dest" --destination-container $containerName --account-name $storageAccountName --auth-mode login -o tsv
    }
}