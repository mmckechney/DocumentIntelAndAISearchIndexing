#az login
param
(
	[Parameter(Mandatory=$true)]
    [string] $appName,
	[Parameter(Mandatory=$true)]
	[string] $location,
	[string] $azureOpenAiEmbeddingModel,
	[string] $embeddingModelVersion,
	[ValidateRange(1000, 8191)]
	[int] $embeddingMaxTokens = 8191,
	[string] $azureOpenAiChatModel,
	[string] $chatModelVersion,
	[string] $myPublicIp, 
	[Parameter(Mandatory=$true)]
	[ValidateRange(1, 10)]
	[int] $docIntelligenceInstanceCount = 1,
	[bool] $codeDeployOnly = $false,
	[Parameter(Mandatory=$true)]
	[ValidateSet('round-robin', 'priority')]
	[string] $loadBalancingType,
	<#
	.PARAMETER includeGeneralIndex
	Include all indexed documents in an all-inclusive 'general' index.

	.DESCRIPTION
	Specifies whether to include all indexed documents in an all-inclusive 'general' index. 
	If set to $true, all indexed documents will be included in the 'general' index and their named index. 
	If set to $false, documents will be included in their own named index.
	#>
	[bool] $includeGeneralIndex = $true
)

$error.Clear()
$ErrorActionPreference = 'Stop'

Write-Host "Getting public IP" -ForegroundColor DarkCyan
if([string]::IsNullOrWhiteSpace($myPublicIp))
{
    $myPublicIp = (Invoke-WebRequest https://api.ipify.org?format=text).Content.Trim()
	Write-Host "Public IP: $myPublicIp" -ForegroundColor Green
}

Write-Host "Getting current user object id" -ForegroundColor DarkCyan
$currentUserObjectId = az ad signed-in-user show -o tsv --query id
Write-Host "Current User Object Id: $currentUserObjectId" -ForegroundColor Green



if(!$?){ exit }

if($codeDeployOnly -eq $false)
{

	if($loadBalancingType -eq "priority")
	{
		Write-Host "Building priority load balancing policy" -ForegroundColor DarkCyan
		$arrayList = [System.Collections.ArrayList]::new()
		$params = (az bicep build-params --file ./infra/main.bicepparam --stdout | ConvertFrom-Json -depth 100 ).parametersJson | ConvertFrom-Json -depth 100
		foreach($oai in  $params.parameters.openAIInstances.value)
		{
			$beName = "OPENAI$($oai.suffix.ToUpper())"
			$item = "backends.Add(new JObject() {{ ""backend-id"", ""$($beName)"" }, { ""priority"", $($oai.priority) }, { ""isThrottling"", false }, { ""retryAfter"", DateTime.MinValue }}); "
			$arrayList.Add($item)
		}
		
		$policy = Get-Content "./infra/APIM/priority-load-balance-policy.xml" -Raw
		$policy = $policy -replace "{{BACKENDS}}", ($arrayList -join "`r`n`t`t`t`t`t")
		Write-Host "Writing priority load balancing policy XML with $($arrayList.Count) backends" -ForegroundColor DarkCyan
		$policy | Set-Content -Path "./infra/APIM/priority-load-balance-policy-main.xml"
	}

	Write-Host "Deploying resources to Azure" -ForegroundColor DarkCyan
	$output = az deployment sub create --location $location  --template-file ./infra/main.bicep `
		--parameters ./infra/main.bicepparam `
		--parameters location=$location `
		appName=$appName `
		myPublicIp=$myPublicIp `
		docIntelligenceInstanceCount=$docIntelligenceInstanceCount `
		currentUserObjectId=$currentUserObjectId  `
		includeGeneralIndex=$includeGeneralIndex `
		loadBalancingType=$loadBalancingType

	# Write-Host $output -ForegroundColor DarkGreen
	if(!$?){ exit }
	if($output -contains "ERROR")
	{
		Write-Host $output -ForegroundColor Red
		exit
	}

	$outputObj = $output | ConvertFrom-Json -Depth 10
	# Write-Host $outputObj -ForegroundColor Cyan
	$resourceGroupName = $outputObj.properties.outputs.resourceGroupName.value
	$funcProcess = $outputObj.properties.outputs.processFunctionName.value
	$funcAiSearch = $outputObj.properties.outputs.aiSearchIndexFunctionName.value
	$funcMove = $outputObj.properties.outputs.moveFunctionName.value
	$funcQueue = $outputObj.properties.outputs.queueFunctionName.value
	$funcQuestions = $outputObj.properties.outputs.questionsFunctionName.value

	if(!$?){ exit }
}
else {
	
	$resourceGroupName ="rg-$appName-$location"
	$funcProcess = "func-$appName-Intelligence-$location"
	$funcMove = "func-$appName-Mover-$location"
	$funcQueue = "func-$appName-Queueing-$location"
	$funcAiSearch = "func-$appName-AiSearch-$location"
	$funcQuestions = "func-$appName-AskQuestions-$location"
}
if(!$?){ exit }

Write-Host "Resource Group Name: $resourceGroupName" -ForegroundColor Green
Write-Host "Queueing Function: $funcQueue" -ForegroundColor Green
Write-Host "Doc Intel Processing Function: $funcProcess" -ForegroundColor Green
Write-Host "AI Embedding and Search Function: $funcAiSearch" -ForegroundColor Green
Write-Host "File Moving Function: $funcMove" -ForegroundColor Green

if(!$?){ exit }
###########################
## Code Deployment
###########################

$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
#dotnet clean -c release
#dotnet clean -c debug
$childPath = "bin/Release/net8.0/publish"
$zip = $scriptDir + "build.zip"


Write-Host "Deploying Ask Questions Function App" -ForegroundColor DarkCyan
Push-Location -Path DocumentQuestionsFunction
#dotnet clean .
dotnet publish .
$source = Join-Path -Path $pwd.Path -ChildPath $childPath
if(Test-Path $zip) { Remove-Item $zip }
[io.compression.zipfile]::CreateFromDirectory($source,$zip)
az webapp deploy --name $funcQuestions --resource-group $resourceGroupName --src-path $zip --type zip
Pop-Location

if(!$?){ exit }

Write-Host "Deploying Document Intelligence Function App" -ForegroundColor DarkCyan
Push-Location -Path DocumentIntelligenceFunction
#dotnet clean .
dotnet publish .
$source = Join-Path -Path $pwd.Path -ChildPath $childPath
if(Test-Path $zip) { Remove-Item $zip }
[io.compression.zipfile]::CreateFromDirectory($source,$zip)
az webapp deploy --name $funcProcess --resource-group $resourceGroupName --src-path $zip --type zip
Pop-Location

if(!$?){ exit }

Write-Host "Deploying AI Search Indexing Function App" -ForegroundColor DarkCyan
Push-Location -Path .\AiSearchIndexingFunction
#dotnet clean .
dotnet publish .
$source = Join-Path -Path $pwd.Path -ChildPath $childPath
$zip = $scriptDir + "build.zip"
if(Test-Path $zip) { Remove-Item $zip }
[io.compression.zipfile]::CreateFromDirectory($source,$zip)
az webapp deploy --name $funcAiSearch --resource-group $resourceGroupName --src-path $zip --type zip
Pop-Location

if(!$?){ exit }

Write-Host "Deploying File Mover Function App" -ForegroundColor DarkCyan
Push-Location -Path ProcessedFileMover
#dotnet clean .
dotnet publish .
$source = Join-Path -Path $pwd.Path -ChildPath $childPath
if(Test-Path $zip) { Remove-Item $zip }
[io.compression.zipfile]::CreateFromDirectory($source,$zip)
az webapp deploy --name $funcMove --resource-group $resourceGroupName --src-path $zip --type zip
Pop-Location

if(!$?){ exit }

Write-Host "Deploying Document Queueing Function App" -ForegroundColor DarkCyan
Push-Location -Path DocumentQueueingFunction
#dotnet clean .
dotnet publish .
$source = Join-Path -Path $pwd.Path -ChildPath $childPath
if(Test-Path $zip) { Remove-Item $zip }
[io.compression.zipfile]::CreateFromDirectory($source,$zip)
az webapp deploy --name $funcQueue --resource-group $resourceGroupName --src-path $zip --type zip
Pop-Location


