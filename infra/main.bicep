
targetScope = 'subscription'

param appName string
param location string
param myPublicIp string = ''
param docIntelligenceInstanceCount int = 1
param currentUserObjectId string

param azureOpenAiResourceGroupName string
param azureOpenAIAccountName string
param azureOpenAIEmbeddingModel string
param azureOpenAIEmbeddingDeployment string
param azureOpenAiEmbeddingMaxTokens int 
param includeGeneralIndex bool = true

var appNameLc = toLower(appName)
var resourceGroupName = 'rg-${appName}-demo-${location}'
var serviceBusNs = 'sbns-${appName}-demo-${location}'
var formStorageAcct = 'stor${appNameLc}demo${location}'
var funcStorageAcct = 'fstor${appNameLc}demo${location}'
var formRecognizer = 'docintel-${appName}-demo-${location}'

var vnet = 'vnet-${appName}-demo-${location}'
var subnet = 'subn-${appName}-demo-${location}'
var nsg = 'nsg-${appName}-demo-${location}'
var funcsubnet = 'subn-${appName}-func-demo-${location}'
var funcAppPlan = 'fcnplan-${appName}-demo-${location}'
var funcProcess = 'fcn-${appName}Intelligence-demo-${location}'
var funcMove = 'fcn-${appName}Mover-demo-${location}'
var funcQueue = 'fcn-${appName}Queueing-demo-${location}'
var aiSearchIndexFunctionName = 'fcn-${appName}AiSearch-demo-${location}'
var keyvaultName = 'kv-${appName}-demo-${location}'
var formQueueName = 'docqueue'
var processedQueueName = 'processedqueue'
var toIndexQueueName = 'toindexqueue'
var aiSearchName = 'aisearch-${appName}-demo-${location}'
var appInsightsName = 'appinsights-${appName}-demo-${location}'
var logAnalyticsName = 'loganalytics-${appName}-demo-${location}'


var documentStorageContainer = 'documents'
var processResultsContainer = 'processresults'
var completedContainer = 'completed'

	resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
		name: resourceGroupName
		location: location
	}


	module networking 'networking.bicep' = {
		name: 'networking'
		scope: resourceGroup(resourceGroupName)
		params: {
			vnet: vnet
			subnet: subnet
			nsg: nsg
			funcsubnet: funcsubnet
			location: location
			myPublicIp: myPublicIp
		}
		dependsOn: [
			rg
		]
	}

module appInsights 'appinsights.bicep' = {
	name: 'appInsigts'
	scope: resourceGroup(resourceGroupName)
	params: {
		appInsightsName: appInsightsName
		logAnalyticsName : logAnalyticsName
		location: location
		aiSearchIndexFunctionName: aiSearchIndexFunctionName
		funcMove: funcMove
		funcQueue: funcQueue
		funcProcess: funcProcess
	}
	dependsOn: [
		rg
	]
}

module storage 'storage.bicep' = {
	name: 'storage'
	scope: resourceGroup(resourceGroupName)
	params: {
		formStorageAcct: formStorageAcct
		funcStorageAcct: funcStorageAcct
		myPublicIp: myPublicIp
		location: location
		subnetIds: networking.outputs.subnetIds
		completedContainer: completedContainer
		documentStorageContainer: documentStorageContainer
		processResultsContainer: processResultsContainer
		keyVaultName:	keyvaultName
	}
	dependsOn: [
		rg
		networking
		keyvault
	]
}

module docIntelligence 'documentintelligence.bicep' = {
	name: 'docintelligence'
	scope: resourceGroup(resourceGroupName)
	params: {
		docIntelligenceName: formRecognizer
		docIntelligenceInstanceCount: docIntelligenceInstanceCount
		location: location
		keyVaultName: keyvaultName
	}
	dependsOn: [
		rg
		networking
		keyvault
	]
}

module servicebus 'servicebus.bicep' = {
	name: 'serviceBus'
	scope: resourceGroup(resourceGroupName)
	params: {
		serviceBusNs: serviceBusNs
		location: location
		formQueueName: formQueueName
		processedQueueName: processedQueueName
		toIndexQueueName: toIndexQueueName
		keyVaultName: keyvaultName
	}
	dependsOn: [
		rg
		networking
		keyvault
	]
}

module keyvault 'keyvault.bicep' = {
	name: 'keyvault'
	scope: resourceGroup(resourceGroupName)
	params: {
		keyVaultName: keyvaultName
		location: location
	}
	dependsOn: [
		rg
		networking
	]
}

module functions 'functions.bicep' = {
	name: 'functions'
	scope: resourceGroup(resourceGroupName)
	params: {
		funcAppPlan: funcAppPlan
		processFunctionName: funcProcess
		moveFunctionName: funcMove
		queueFunctionName: funcQueue
		formStorageAcctName: formStorageAcct
		functionStorageAcctName: funcStorageAcct
		processedQueueName: processedQueueName
		serviceBusNs: serviceBusNs
		functionSubnetId: networking.outputs.functionSubnetId
		keyVaultUri: keyvault.outputs.keyVaultUri
		location: location
		formQueueName: formQueueName
		completedContainer: completedContainer
		documentStorageContainer: documentStorageContainer
		processResultsContainer: processResultsContainer
		aiSearchIndexFunctionName: aiSearchIndexFunctionName
		toIndexQueueName: toIndexQueueName
		aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
		azureOpenAiResourceGroupName: azureOpenAiResourceGroupName
		azureOpenAiAccountName: azureOpenAIAccountName
		openAiEmbeddingModel: azureOpenAIEmbeddingModel
		openAiEmbeddingDeployment: azureOpenAIEmbeddingDeployment
		appInsightsName: appInsightsName
		azureOpenAiEmbeddingMaxTokens: azureOpenAiEmbeddingMaxTokens
		includeGeneralIndex: includeGeneralIndex
	}
	dependsOn: [
		rg
		networking
		storage
		keyvault
		servicebus
		appInsights
	]
}

module roleAssigments 'roleassignments.bicep' = {
	name: 'roleAssigments'
	scope: resourceGroup(resourceGroupName)
	params: {
		docIntelligencePrincipalIds: docIntelligence.outputs.docIntelligencePrincipalIds
		storageAccountName: formStorageAcct
		moveFunctionId: functions.outputs.moveFunctionId
		processFunctionId: functions.outputs.processFunctionId
		queueFunctionId: functions.outputs.queueFunctionId
		aiSearchIndexFunctionId: functions.outputs.aiSearchIndexFunctionId
		currentUserObjectId : currentUserObjectId
	}
	dependsOn: [
		rg
		keyvault
		storage
		docIntelligence
		servicebus
		functions
		networking
	]
}

module aiSearch 'aisearch.bicep' = {
	name: 'aiSearch'
	scope: resourceGroup(resourceGroupName)
	params: {
		aiSearchName: aiSearchName
		keyVaultName: keyvaultName
		location: location
	}
	dependsOn: [
		rg
		keyvault
	]
}

module keyvaultSecrets 'keyvaultkeys.bicep' = {
	name: 'keyvaultSecrets'
	scope: resourceGroup(resourceGroupName)
	params: {
		keyvault: keyvaultName
		docIntelKeyArray: docIntelligence.outputs.docIntellKeyArray
		openAiResourceGroupName: azureOpenAiResourceGroupName
		openAiAccountName: azureOpenAIAccountName
	}
	dependsOn: [
		rg
		keyvault
		docIntelligence
	]
}
