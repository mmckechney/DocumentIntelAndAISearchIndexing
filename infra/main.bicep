import * as customTypes from './constants/customTypes.bicep'
targetScope = 'subscription'

param appName string
param appNameSafe string
param location string
param myPublicIp string
param docIntelligenceInstanceCount int
param currentUserObjectId string
param aiIndexName string = 'documentindex'
param serviceBusSku string = 'Standard'
param functionValues customTypes.functionValue[] 

@description('Azure AI Foundry deployment configuration.')
param foundryConfig customTypes.foundryConfig

@description('Persistent agent identifier inside the Azure AI Foundry project (optional).')
param foundryAgentId string = ''

var abbrs = loadJsonContent('./constants/abbreviations.json')
var appNameLc = toLower(appNameSafe)

var resourceGroupName = '${abbrs.resourceGroup}${appName}'
var serviceBusNs = '${abbrs.serviceBusNamespace}${appName}-${location}'
var formStorageBase = '${abbrs.storageAccount}${appNameLc}${location}'
var formStorageAcct = length(formStorageBase) > 24 ? substring(formStorageBase, 0, 24) : formStorageBase
var funcStorageBase = '${abbrs.storageAccount}${appNameLc}func${location}'
var funcStorageAcct = length(funcStorageBase) > 24 ? substring(funcStorageBase, 0, 24) : funcStorageBase
var docIntelligence = '${abbrs.documentIntelligence}${appName}${location}'

var vnet = '${abbrs.virtualNetwork}${appName}-${location}'
var subnet = '${abbrs.virtualNetworkSubnet}${appName}-${location}'
var nsg = '${abbrs.networkSecurityGroup}${appName}-${location}'
var funcsubnet = '${abbrs.virtualNetworkSubnet}${appName}-func-${location}'
var apimsubnet = '${abbrs.virtualNetworkSubnet}${appName}-apim-${location}'
var containerRegistryBase = toLower('${abbrs.containerRegistry}${appNameLc}${location}')
var containerRegistryName = length(containerRegistryBase) > 50 ? substring(containerRegistryBase, 0, 50) : containerRegistryBase
var containerAppEnvironmentBase = toLower('${abbrs.containerAppsEnvironment}${appName}-${location}')
var containerAppEnvironmentName = length(containerAppEnvironmentBase) > 32 ? substring(containerAppEnvironmentBase, 0, 32) : containerAppEnvironmentBase

var keyvaultNameBase = '${abbrs.keyVault}${appName}-${location}'
// Key Vaults allow up to 24 chars; trim to 24 if needed
var keyvaultName = length(keyvaultNameBase) > 24 ? substring(keyvaultNameBase, 0, 24) : keyvaultNameBase

var aiSearchName = '${abbrs.aiSearch}${appNameLc}-demo-${location}'
var appInsightsName = '${abbrs.applicationInsights}${appName}-${location}'
var logAnalyticsName = '${abbrs.logAnalyticsWorkspace}${appName}-${location}'
var managedIdentityName = '${abbrs.managedIdentity}${appName}-${location}'
var cosmosDbName = 'documentIndexing'
var cosmosContainerName = 'processTracker'
var cosmosDbAccountName = toLower('${abbrs.cosmosDBNoSQL}${appName}-${location}')

var foundryResourceName = '${abbrs.foundryResource}${appName}-${location}'
var foundryProjectName = '${abbrs.foundryProject}${appName}-${location}'

var documentStorageContainer = 'documents'
var processResultsContainer = 'processresults'
var completedContainer = 'completed'

var customFieldQueueName = 'customfieldqueue'
var docQueueName = 'docqueue'
var moveQueueName = 'movequeue'
var toIndexQueueName = 'toindexqueue'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
	tags: {
		SecurityControl: 'Ignore'
	}
}

module managedIdentity 'core/managed-identity.bicep' = {
	name: 'managedIdentity'
	scope: rg
	params: {
		name: managedIdentityName
		location: location
	}
}

module foundry 'foundry/foundry.bicep' = {
	name: 'foundry'
	scope: rg
	params: {
		aiFoundryResourceName: foundryResourceName
		location: location
		tags: {
			CreatedBy: currentUserObjectId
		}
		managedIdentityId: managedIdentity.outputs.id
		projectName: foundryProjectName
		projectDisplayName: foundryConfig.projectDisplayName
		chatModelName: foundryConfig.chatModel.name
		chatModelVersion: foundryConfig.chatModel.version
		chatSku: foundryConfig.chatModel.sku
		chatCapacity: foundryConfig.chatModel.capacity
		embeddingModelName: foundryConfig.embeddingModel.name
		embeddingModelVersion: foundryConfig.embeddingModel.version
		embeddingSku: foundryConfig.embeddingModel.sku
		embeddingCapacity: foundryConfig.embeddingModel.capacity
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
		vnetName: vnet
		subnetName: subnet
		myPublicIp: myPublicIp
	}
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
	}
}

module docIntelligenceService 'core/documentintelligence.bicep' = {
	name: 'docintelligence'
	scope: rg
	params: {
		docIntelligenceName: docIntelligence
		docIntelligenceInstanceCount: docIntelligenceInstanceCount
		location: location
	}
	dependsOn: [
  	networking
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
		subnetName: funcsubnet
		vnetName: vnet
		serviceBusSku: serviceBusSku
	}
	dependsOn: [
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

module containerRegistry 'core/containerregistry.bicep' = {
	name: 'containerRegistry'
	scope: rg
	params: {
		registryName: containerRegistryName
		location: location
	}
}
 
module managedIdentityAcrPull 'core/containerregistry-acr-roleassignment.bicep' = {
	name: 'managedIdentityAcrPull'
	scope: rg
	params: {
		containerRegistryName: containerRegistryName
		principalId: managedIdentity.outputs.principalId
	}
	dependsOn: [
		containerRegistry
	]
}

module containerEnvironment 'core/containerapp-environment.bicep' = {
	name: 'containerEnvironment'
	scope: rg
	params: {
		name: containerAppEnvironmentName
		location: location
		logAnalyticsCustomerId: appInsights.outputs.logAnalyticsCustomerId
		logAnalyticsSharedKey: appInsights.outputs.logAnalyticsSharedKey
		infrastructureSubnetId: networking.outputs.functionSubnetId
	}
}

module functions 'containerapp/containerapps.bicep' = {
	name: 'functions'
	scope: rg
	params: {
		location: location
		functionValues: functionValues
		managedEnvironmentId: containerEnvironment.outputs.id
		containerRegistryServer: containerRegistry.outputs.loginServer
		containerRegistryIdentityResourceId: managedIdentity.outputs.id
		managedIdentityId: managedIdentity.outputs.id
		managedIdentityClientId: managedIdentity.outputs.clientId
		formStorageAcctName: formStorageAcct
		documentStorageContainer: documentStorageContainer
		processResultsContainer: processResultsContainer
		completedContainer: completedContainer
		serviceBusNs: serviceBusNs
		docQueueName: docQueueName
		customFieldQueueName: customFieldQueueName
		moveQueueName: moveQueueName
		toIndexQueueName: toIndexQueueName
		aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
		foundryProjectEndpoint: foundry.outputs.projectEndpoint
		cosmosDbEndpoint: cosmosDb.outputs.cosmosDbEndpoint
		serviceBusFullyQualifiedNamespace: servicebus.outputs.serviceBusFullyQualifiedNamespace
		documentIntelligenceEndpoint: docIntelligenceService.outputs.docIntellEndpoint
		documentIntelligenceEndpoints: string(docIntelligenceService.outputs.docIntellEndpoints)
		foundryEmbeddingMaxTokens: foundryConfig.embeddingMaxTokens
		aiIndexName: aiIndexName
		foundryChatDeployment: foundry.outputs.chatDeploymentName
		foundryEmbeddingModel: foundry.outputs.embeddingModel
		foundryEmbeddingDeployment: foundry.outputs.embeddingDeploymentName
		foundryAgentId: foundryAgentId
		cosmosDbName: cosmosDbName
		cosmosContainerName: cosmosContainerName
		appInsightsConnectionString: appInsights.outputs.connectionString
		appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
		usePlaceholderImage: true
	}
	dependsOn: [
		storage
		managedIdentityAcrPull
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
		containerRegistryName: containerRegistry.outputs.name
		cosmosAccountName: cosmosDb.outputs.cosmosDbAccountName
		cosmosAccountResourceGroup: resourceGroupName
	}
}

module aiSearch 'core/aisearch.bicep' = {
	name: 'aiSearch'
	scope: rg
	params: {
		aiSearchName: aiSearchName
		location: location
	}
}


output resourceGroupName string = resourceGroupName
output foundryAccountName string = foundry.outputs.accountName
output foundryProjectEndpoint string = foundry.outputs.projectEndpoint
output foundryChatDeployment string = foundry.outputs.chatDeploymentName
output foundryEmbeddingDeployment string = foundry.outputs.embeddingDeploymentName
output containerAppsEnvironmentName string = containerEnvironment.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output services array = functions.outputs.services
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
