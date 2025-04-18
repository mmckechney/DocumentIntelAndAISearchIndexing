#az login

# Regional service availability: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table
param
(
	[ValidateSet('Full', 'InfraOnly','CodeOnly', 'SettingsOnly', 'BuiltCodeOnly')]
	[string] $deployAction = 'Full',
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
$WarningPreference = "SilentlyContinue"


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

Write-Host "Deploying Azure Container Registry and UAMI resources" -ForegroundColor DarkCyan
$output = az deployment sub create --name "$deploymentName-initial" --location $location  --template-file ./infra/initial.bicep `
	--parameters location=$location `
		appName=$appName `
	
if(!$?){ exit }
# $acrName = $outputObj.properties.outputs.name.value
# $acrLoginServer = $outputObj.properties.outputs.name.value


if($deployAction -eq "Full" -or $deployAction -eq "CodeOnly")
{
	###########################
	## Container Build and Push
	###########################

	# Create an array of objects where each object has function name, project path, and Docker image name
	$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path

	$containerRegistry = "cr$($appName.ToLower())$($location)"
	$containerRegistryUrl = "$containerRegistry.azurecr.io"
	$funcProcess = "func-$appName-Intelligence-$location"
	$funcCustomField = "func-$appName-CustomField-$location"
	$funcMove = "func-$appName-Mover-$location"
	$funcQueue = "func-$appName-Queueing-$location"
	$funcAiSearch = "func-$appName-AiSearch-$location"
	$funcQuestions = "func-$appName-AskQuestions-$location"

	$functionApps = @(
		@{ name = $funcAiSearch; projectPath = "AiSearchIndexingFunction"; imageName = "ai-search-indexing-function:latest"; localPort=7103 },
		@{ name = $funcQueue; projectPath = "DocumentQueueingFunction"; imageName = "document-queueing-function:latest"; localPort=7100 },
		@{ name = $funcProcess; projectPath = "DocumentIntelligenceFunction"; imageName = "document-intelligence-function:latest"; localPort=7101 },
		@{ name = $funcCustomField; projectPath = "CustomFieldExtractionFunction"; imageName = "custom-field-extraction-function:latest"; localPort=7102 },
		@{ name = $funcQuestions; projectPath = "DocumentQuestionsFunction"; imageName = "document-questions-function:latest"; localPort=7104 },
		@{ name = $funcMove; projectPath = "ProcessedFileMover"; imageName = "processed-file-mover-function:latest"; localPort=7105 }
	)


	# Login to ACR
	Write-Host "Logging in to Azure Container Registry: $containerRegistry" -ForegroundColor DarkCyan
	$_ = az acr login -n $containerRegistry  --expose-token
	if(!$?){ exit }
	Write-Host "Building and pushing Docker images for all Function Apps.." -ForegroundColor DarkCyan
	if(($deployAction -eq "Full" -or $deployAction -eq "CodeOnly") -and $deployAction -ne "InfraOnly" )
	{

		Write-Host "Cleaning up bin and obj directories in $scriptDir" -ForegroundColor DarkCyan
		$binDirs = Get-ChildItem $scriptDir -Include bin -Recurse -Force 
		Write-Host "Found bin directories: $($binDirs.Count)" -ForegroundColor Green
		foreach ($binDir in $binDirs) {
			Write-Host "Removing bin directory: $($binDir.FullName)" -ForegroundColor DarkCyan
			Remove-Item $binDir.FullName -Recurse -Force
		}

		$objDirs = Get-ChildItem $scriptDir -Include obj -Recurse -Force | Remove-Item -Recurse -Force
		Write-Host "Found obj directories: $($objDirs.Count)" -ForegroundColor Green
		foreach ($objDir in $objDirs) {
			Write-Host "Removing obj directory: $($objDir.FullName)" -ForegroundColor DarkCyan
			Remove-Item $objDir.FullName -Recurse -Force
		}


		# Create an array to hold all job objects
		$jobs = @()
		
		# Loop through each function app and queue a build in ACR
		foreach($funcApp in $functionApps) {
			$functionName = $funcApp.name
			$functionPath = $funcApp.projectPath
			$imageName = $funcApp.imageName
			
  			Write-Host "Starting ACR Task to build image $imageName for $functionName Function App" -ForegroundColor DarkCyan
		
			# Create a new ACR build task (build directly from current directory) as a background job
			$acrBuildCmd = "az acr build --registry $containerRegistry --image $imageName --file ./$functionPath/Dockerfile ."
			
			# Start the build as a background job
			# $job = Start-Job -ScriptBlock {
			# 	param($acrBuildCmd, $functionName, $imageName)
				
				Write-Output "Building $functionName with image $imageName"
				#$output = 
				Invoke-Expression $acrBuildCmd
				
			# 	# Return job results
			# 	[PSCustomObject]@{
			# 		FunctionName = $functionName
			# 		ImageName = $imageName
			# 		Output = $output
			# 		Success = $LASTEXITCODE -eq 0
			# 	}
			# } -ArgumentList $acrBuildCmd, $functionName, $imageName
			
			# # Add job to tracking array
			# $jobs += @{
			# 	Job = $job
			# 	FunctionName = $functionName
			# 	ImageName = $imageName
			# }
		}
	
		# Monitor all jobs and wait for completion
		# Write-Host "Monitoring parallel container builds..." -ForegroundColor Yellow
		
		# $failedBuilds = @()
		
		# # Wait for all jobs to complete
		# foreach ($jobInfo in $jobs) {
		# 	$job = $jobInfo.Job
		# 	$functionName = $jobInfo.FunctionName
		# 	$imageName = $jobInfo.ImageName
			
		# 	Write-Host "Waiting for $functionName build to complete..." -ForegroundColor Cyan
		# 	$result = $job | Wait-Job | Receive-Job
			
		# 	if ($result.Success) {
		# 		Write-Host "✅ Successfully built $functionName image: $imageName" -ForegroundColor Green
		# 	} else {
		# 		Write-Host "❌ Failed to build $functionName image: $imageName" -ForegroundColor Red
		# 		Write-Host "Output: $($result.Output)" -ForegroundColor Yellow
		# 		$failedBuilds += $functionName
		# 	}
		# }
		
		# # Clean up jobs
		# $jobs | ForEach-Object { $_.Job | Remove-Job -Force }
		
		# # Check if any builds failed and exit if needed
		# if ($failedBuilds.Count -gt 0) {
		# 	Write-Host "The following builds failed: $($failedBuilds -join ', ')" -ForegroundColor Red
		# 	exit 1
		# }
	}
}




if($deployAction-eq "Full" -or $deployAction -eq "InfraOnly")
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
		--parameters `
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


if($deployAction -ne "InfraOnly" )
{
	$functionApps | ForEach-Object {
		$functionName = $_.name
		$functionPath = $_.projectPath
		$port = $_.localPort

		Write-Host ""
		Write-Host "Creating local settings file for $functionPath folder" -ForegroundColor DarkCyan
		Push-Location -Path $functionPath
			$env = az containerapp show -n $functionName -g $resourceGroupName --query "properties.template.containers[0].env" -o json
			$jsonObject = $env | ConvertFrom-Json  
		
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
}

