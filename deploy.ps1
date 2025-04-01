#az login
param
(
	[Parameter(Mandatory=$true)]
    [string] $appName,
	[Parameter(Mandatory=$true)]
	[string] $location,
	[Parameter(Mandatory=$true)]
	[ValidateRange(1, 10)]
	[int] $docIntelligenceInstanceCount = 1,
	[Parameter(Mandatory=$true)]
	[ValidateSet('round-robin', 'priority')]
	[string] $loadBalancingType = 'priority',
	[ValidateSet('Full', 'CodeOnly', 'SettingsOnly')]
	[string] $deployAction = 'Full',
	[string] $aiIndexName = 'general',
	[ValidateSet('Basic', 'Standard', 'Premium')]
	[string] $serviceBusSku = 'Standard',
	[string] $azureOpenAiEmbeddingModel,
	[string] $embeddingModelVersion,
	[ValidateRange(1000, 8191)]
	[int] $embeddingMaxTokens = 8191,
	[string] $azureOpenAiChatModel,
	[string] $chatModelVersion,
	[string] $myPublicIp, 
	[string] $deploymentName
)


if($deploymentName -eq "")
{
	$deploymentName = "deploy-$appName-$location"
}
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

if($deployAction-eq "Full")
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
	$output = az deployment sub create --name $deploymentName --location $location  --template-file ./infra/main.bicep `
		--parameters ./infra/main.bicepparam `
		--parameters location=$location `
		appName=$appName `
		myPublicIp=$myPublicIp `
		docIntelligenceInstanceCount=$docIntelligenceInstanceCount `
		currentUserObjectId=$currentUserObjectId  `
		aiIndexName=$aiIndexName `
		loadBalancingType=$loadBalancingType `
		serviceBusSku=$serviceBusSku 

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
	$funcCustomField = $outputObj.properties.outputs.customFieldFunctionName.value

	if(!$?){ exit }
}
else {
	
	$resourceGroupName ="rg-$appName-$location"
	$funcProcess = "func-$appName-Intelligence-$location"
	$funcCustomField = "func-$appName-CustomField-$location"
	$funcMove = "func-$appName-Mover-$location"
	$funcQueue = "func-$appName-Queueing-$location"
	$funcAiSearch = "func-$appName-AiSearch-$location"
	$funcQuestions = "func-$appName-AskQuestions-$location"
}
if(!$?){ exit }

Write-Host "Resource Group Name: $resourceGroupName" -ForegroundColor Green
Write-Host "Queueing Function: $funcQueue" -ForegroundColor Green
Write-Host "Doc Intel Processing Function: $funcProcess" -ForegroundColor Green
Write-Host "Custom Field Extraction Function: $funcCustomField" -ForegroundColor Green
Write-Host "AI Embedding and Search Function: $funcAiSearch" -ForegroundColor Green
Write-Host "File Moving Function: $funcMove" -ForegroundColor Green

if(!$?){ exit }
###########################
## Code Deployment
###########################

#create an array of object where each object has function name, path, and zip file name
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path

$functionApps = @(
	@{ name = $funcQueue; projectPath = "DocumentQueueingFunction"; zipFile = "$($scriptDir)\DocumentQueueingFunction.zip"; localPort=7100 },
	@{ name = $funcProcess; projectPath = "DocumentIntelligenceFunction"; zipFile = "$($scriptDir)\DocumentIntelligenceFunction.zip" ; localPort=7101},
	@{ name = $funcCustomField; projectPath = "CustomFieldExtractionFunction"; zipFile = "$($scriptDir)\CustomFieldExtractionFunction.zip" ; localPort=7102},
	@{ name = $funcAiSearch; projectPath = "AiSearchIndexingFunction"; zipFile = "$($scriptDir)\AiSearchIndexingFunction.zip"; localPort=7103 },
	@{ name = $funcQuestions; projectPath = "DocumentQuestionsFunction"; zipFile = "$($scriptDir)\DocumentQuestionsFunction.zip" ; localPort=7104},
	@{ name = $funcMove; projectPath = "ProcessedFileMover"; zipFile = "$($scriptDir)\ProcessedFileMover.zip" ; localPort=7105}
	
)

if($deployAction -eq "Full" -or $deployAction -eq "CodeOnly")
{
	$functionApps | ForEach-Object {
		$functionName = $_.name
		$functionPath = $_.projectPath
		$zipFileName = $_.zipFile

		Write-Host ""
		Write-Host "Building and Zipping publish package for $functionName Function App to $zipFileName" -ForegroundColor DarkCyan
		Push-Location -Path $functionPath
			dotnet publish .
			$source = Join-Path -Path $pwd.Path -ChildPath "bin/Release/net8.0/publish"
			if(Test-Path $zipFileName) { Remove-Item $zipFileName }
			[io.compression.zipfile]::CreateFromDirectory($source,$zipFileName)
		Pop-Location
		if(!$?){ exit }
	}

	$functionApps | ForEach-Object {
		$functionName = $_.name
		$zipFileName = $_.zipFile

		Write-Host ""
		Write-Host "Updating publish policy to allow basic credentals for $functionName..." -ForegroundColor DarkCyan
		$tmp = az resource update --resource-group $resourceGroupName --name ftp --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/$functionName --set properties.allow=true
		$tmp = az resource update --resource-group $resourceGroupName --name scm --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/$functionName --set properties.allow=true
		
		Write-Host "Deploying $functionName Function App from $zipFileName package" -ForegroundColor DarkCyan
		az webapp deploy --name $functionName --resource-group $resourceGroupName --src-path $zipFileName --type zip
		
		Write-Host "Resetting publish policy for $functionName..." -ForegroundColor DarkCyan
		$tmp = az resource update --resource-group $resourceGroupName --name ftp --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/$functionName --set properties.allow=false
		$tmp = az resource update --resource-group $resourceGroupName --name scm --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/$functionName --set properties.allow=false

		if(!$?){ exit }
	}

}


$functionApps | ForEach-Object {
	$functionName = $_.name
	$functionPath = $_.projectPath
	$port = $_.localPort


	Write-Host ""
	Write-Host "Creating local settings file for $functionPath folder" -ForegroundColor DarkCyan
	Push-Location -Path $functionPath
		$appSettings = az functionapp config appsettings list -n $functionName -g $resourceGroupName
		$jsonObject = $appSettings | ConvertFrom-Json  
	  
		# Create a new object for the output format  
		$outputObject = @{  
			IsEncrypted = $false  
			Values = @{} 
			Host = @{  
				"LocalHttpPort" = $port  
			}
		}  
	  
		# Loop through each item in the JSON array and add it to the 'Values' dictionary  
		foreach ($item in $jsonObject) {  
			$outputObject.Values[$item.name] = $item.value  
		}  

		# Convert the output object to JSON  
		$jsonOutput = $outputObject | ConvertTo-Json -Depth 100  
		
		# Write the output JSON to a file  
		$jsonOutputPath = 'local.settings.json'  
		$jsonOutput | Set-Content -Path $jsonOutputPath  
		
		Write-Host "Local settings file created for $functionPath folder" -ForegroundColor DarkCyan
	Pop-Location
	if(!$?){ exit }
}

