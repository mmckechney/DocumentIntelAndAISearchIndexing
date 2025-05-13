import * as customTypes from './constants/customTypes.bicep'
targetScope = 'subscription'

param appName string
param location string
param myPublicIp string
param docIntelligenceInstanceCount int
param currentUserObjectId string
param aiIndexName string = 'documentindex'
param apiManagementPublisherEmail string
param apiManagementPublisherName string
param serviceBusSku string = 'Standard'
param functionValues customTypes.functionValue[] 
param apimSku customTypes.apimSkuInfo = {
	name: 'StandardV2'
	capacity: 1
}
@allowed(['EP1', 'P0V3', 'P1V3', 'P2V3'])
param funcAppPlanSku string


@description('OpenAI instances to deploy. Defaults to 2 across different regions.')
param openAiConfigs customTypes.openAIConfigs

var abbrs = loadJsonContent('./constants/abbreviations.json')
var appNameLc = toLower(appName)

var resourceGroupName = '${abbrs.resourceGroup}${appName}'
var serviceBusNs = '${abbrs.serviceBusNamespace}${appName}-${location}'
var formStorageAcct = '${abbrs.storageAccount}${appNameLc}${location}'
var funcStorageAcct = '${abbrs.storageAccount}${appNameLc}func${location}'
var docIntelligence = '${abbrs.documentIntelligence}${appName}-${location}'

var vnet = '${abbrs.virtualNetwork}${appName}-${location}'
var subnet = '${abbrs.virtualNetworkSubnet}${appName}-${location}'
var nsg = '${abbrs.networkSecurityGroup}${appName}-${location}'
var funcsubnet = '${abbrs.virtualNetworkSubnet}${appName}-func-${location}'
var apimsubnet = '${abbrs.virtualNetworkSubnet}${appName}-apim-${location}'
var funcAppPlan = '${abbrs.appServicePlan}${appName}-${location}'

var keyvaultName = '${abbrs.keyVault}${appName}-${location}'

var aiSearchName = '${abbrs.aiSearch}${appNameLc}-demo-${location}'
var appInsightsName = '${abbrs.applicationInsights}${appName}-${location}'
var logAnalyticsName = '${abbrs.logAnalyticsWorkspace}${appName}-${location}'
var managedIdentityName = '${abbrs.managedIdentity}${appName}-${location}'
var apiManagementName = '${abbrs.apiManagementService}${appName}-${location}'

var cosmosDbName = 'documentIndexing'
var cosmosContainerName = 'processTracker'
var cosmosDbAccountName = toLower('${abbrs.cosmosDBNoSQL}${appName}-${location}')

var documentStorageContainer = 'documents'
var processResultsContainer = 'processresults'
var completedContainer = 'completed'

var customFieldQueueName = 'customfieldqueue'
var docQueueName = 'docqueue'
var moveQueueName = 'movequeue'
var toIndexQueueName = 'toindexqueue'

var openAiApiName = 'openai'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
}

module managedIdentity 'core/managed-identity.bicep' = {
	name: 'managedIdentity'
	scope: rg
	params: {
		name: managedIdentityName
		location: location
	}
}

module networkSecurityGroup 'core/networksecuritygroup.bicep' = {
	name: 'networkSecurityGroup'
	scope: rg
	params: {
		nsg: nsg
		myPublicIp: myPublicIp
		location: location
	}
}

module cosmosDb 'core/cosmos.bicep' = {
	name: 'cosmosDb'
	scope: rg
	params: {
		databaseName: cosmosDbName
		cosmosContainerName: cosmosContainerName
		cosmosDbAccountName: cosmosDbAccountName
		functionSubnetId: networking.outputs.functionSubnetId
		apimSubnetId: networking.outputs.apimSubnetId
		location: location
		keyVaultName: keyvaultName
		vnetName: vnet
		subnetName: subnet
		myPublicIp: myPublicIp
	}
	dependsOn: [
		keyvault
	]
}
module networking 'core/networking.bicep' = {
	name: 'networking'
	scope: rg
	params: {
		vnet: vnet
		subnet: subnet
		nsg: nsg
		funcsubnet: funcsubnet
		location: location
		apimsubnet: apimsubnet
	}
	dependsOn: [
		networkSecurityGroup
	]
}

module appInsights 'core/appinsights.bicep' = {
	name: 'appInsigts'
	scope: rg
	params: {
		appInsightsName: appInsightsName
		logAnalyticsName : logAnalyticsName
		location: location
		functionNames: [for f in functionValues: f.name]
	}
}

module storage 'core/storage.bicep' = {
	name: 'storage'
	scope: rg
	params: {
		formStorageAcct: formStorageAcct
		funcStorageAcct: funcStorageAcct
		myPublicIp: myPublicIp
		location: location
		subnetIds: networking.outputs.storageSubnetIds
		completedContainer: completedContainer
		documentStorageContainer: documentStorageContainer
		processResultsContainer: processResultsContainer
		keyVaultName:	keyvaultName
	}
	dependsOn: [
		keyvault
	]
}

module docIntelligenceService 'core/documentintelligence.bicep' = {
	name: 'docintelligence'
	scope: rg
	params: {
		docIntelligenceName: docIntelligence
		docIntelligenceInstanceCount: docIntelligenceInstanceCount
		location: location
		keyVaultName: keyvaultName
	}
	dependsOn: [
  	networking
		keyvault
	]
}

module servicebus 'core/servicebus.bicep' = {
	name: 'serviceBus'
	scope: rg
	params: {
		serviceBusNs: serviceBusNs
		location: location
		docQueueName: docQueueName
		moveQueueName: moveQueueName
		toIndexQueueName: toIndexQueueName
		customFieldQueueName: customFieldQueueName
		keyVaultName: keyvaultName
		subnetName: funcsubnet
		vnetName: vnet
		serviceBusSku: serviceBusSku
	}
	dependsOn: [
		keyvault
		networking
	]
}

module keyvault 'core/keyvault.bicep' = {
	name: 'keyvault'
	scope: rg
	params: {
		keyVaultName: keyvaultName
		location: location
	}
	dependsOn: [
		networking
	]
}

module functions 'functions/functions.bicep' = {
	name: 'functions'
	scope: rg
	params: {
		funcAppPlan: funcAppPlan
		functionValues: functionValues
		customFieldQueueName: customFieldQueueName
		formStorageAcctName: formStorageAcct
		functionStorageAcctName: funcStorageAcct
		moveQueueName: moveQueueName
		serviceBusNs: serviceBusNs
		functionSubnetId: networking.outputs.functionSubnetId
		keyVaultUri: keyvault.outputs.keyVaultUri
		location: location
		docQueueName: docQueueName
		completedContainer: completedContainer
		documentStorageContainer: documentStorageContainer
		processResultsContainer: processResultsContainer
		toIndexQueueName: toIndexQueueName
		aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
		openAiEmbeddingModel: openAiConfigs.embeddingModel
		appInsightsName: appInsightsName
		aiIndexName: aiIndexName
		managedIdentityId: managedIdentity.outputs.id
		azureOpenAiEmbeddingMaxTokens: openAiConfigs.embeddingMaxTokens
		openAiEndpoint: apiManagement.outputs.gatewayUrl
		openAiChatModel: openAiConfigs.completionModel
		cosmosDbName: cosmosDbName
		cosmosContainerName: cosmosContainerName
		funcAppPlanSku: funcAppPlanSku
	
	}
	dependsOn: [
		storage
		servicebus
		cosmosDb
	]
}

module roleAssigments 'core/roleassignments.bicep' = {
	name: 'roleAssigments'
	scope: rg
	params: {
		docIntelligencePrincipalIds: docIntelligenceService.outputs.docIntelligencePrincipalIds
		userAssignedManagedIdentityPrincipalId: managedIdentity.outputs.principalId
		currentUserObjectId : currentUserObjectId
		functionPrincipalIds: functions.outputs.systemAssignedIdentities
		apimSystemAssignedIdentityPrincipalId: apiManagement.outputs.identity
	}
}

module aiSearch 'core/aisearch.bicep' = {
	name: 'aiSearch'
	scope: rg
	params: {
		aiSearchName: aiSearchName
		keyVaultName: keyvault.outputs.keyVaultName
		location: location
	}
}

module keyvaultSecrets 'core/keyvault-secrets.bicep' = {
	name: 'keyvaultSecrets'
	scope: rg
	params: {
		keyvault: keyvaultName
		docIntelKeyArray: docIntelligenceService.outputs.docIntellKeyArray
	}
	dependsOn: [
		keyvault
	]
}

module apiManagement 'apim/api-management.bicep' = {
	name: 'apiManagement'
	scope: rg
	params: {
		name: apiManagementName
		location: location
		apiManagementIdentityId: managedIdentity.outputs.id
		publisherEmail: apiManagementPublisherEmail
		publisherName: apiManagementPublisherName
		subnetId: networking.outputs.apimSubnetId
		openAIDeployments: openAi.outputs.openAIDeployments
		sku: apimSku
		tags: {
			CreatedBy: currentUserObjectId
		}
	}
	
}

module aoiManamgentSettings 'apim/api-management-settings.bicep' = {
	name: 'apiManagementSettings'
	scope: rg
	params: {
		apiManagementName: apiManagement.outputs.name
		keyVaultUri: keyvault.outputs.keyVaultUri
		keyvaultName: keyvaultName
		openApiApimBackends: apiManagement.outputs.openAIApiBackends
		openAIDeployments: openAi.outputs.openAIDeployments
		openAiApiName: openAiApiName
		appInsightsName: appInsights.outputs.name
		userAssignedIdentityId: managedIdentity.outputs.clientId
	}
	dependsOn: [
		roleAssigments
	]
}

module openAi './openai/openai.bicep' = {
	name: 'openAi'
	scope: rg
	params: {
		openAIInstances: openAiConfigs
		keyvaultName: keyvault.outputs.keyVaultName
		instancePrefix: '${abbrs.openAIService}${appName}-'
		managedIdentityId: managedIdentity.outputs.id
	}
}





output resourceGroupName string = resourceGroupName
output openAINames array = [for i in range(0, length(openAiConfigs.configs)): openAi.outputs.openAIDeployments[i].name]
output openAiChatModel string = openAiConfigs.completionModel
output openAiEmbeddingModel string = openAiConfigs.embeddingModel
output apimName string = apiManagement.outputs.name

