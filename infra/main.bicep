
targetScope = 'subscription'

param appName string
param location string
param myPublicIp string
param docIntelligenceInstanceCount int
param currentUserObjectId string

param azureOpenAIEmbeddingModel string
param embeddingModelVersion string

param azureOpenAIChatModel string
param chatModelVersion string

param embeddingMaxTokens int 

param aiIndexName string

param apiManagementPublisherEmail string
param apiManagementPublisherName string

param serviceBusSku string = 'Standard'

@allowed([
  'round-robin'
  'priority'
])
param loadBalancingType string


type openAIInstanceInfo = {
  name: string?
  location: string
  suffix: string
	priority: int
}


@description('OpenAI instances to deploy. Defaults to 2 across different regions.')
param openAIInstances openAIInstanceInfo[] = [
	{
		name: ''
		location: 'eastus'
		suffix: 'eastus'
		priority: 1
	}
	{
		name: ''
		location: 'candadaeast'
		suffix: 'canadaeast'
		priority: 2
	}
]

var abbrs = loadJsonContent('./constants/abbreviations.json')
var appNameLc = toLower(appName)

var resourceGroupName = '${abbrs.resourceGroup}${appName}-${location}'
var serviceBusNs = '${abbrs.serviceBusNamespace}${appName}-${location}'
var formStorageAcct = '${abbrs.storageAccount}${appNameLc}${location}'
var funcStorageAcct = '${abbrs.storageAccount}${appNameLc}func${location}'
var formRecognizer = '${abbrs.documentIntelligence}${appName}-${location}'

var vnet = '${abbrs.virtualNetwork}${appName}-${location}'
var subnet = '${abbrs.virtualNetworkSubnet}${appName}-${location}'
var nsg = '${abbrs.networkSecurityGroup}${appName}-${location}'
var funcsubnet = '${abbrs.virtualNetworkSubnet}${appName}-func-${location}'
var apimsubnet = '${abbrs.virtualNetworkSubnet}${appName}-apim-${location}'
var funcAppPlan = '${abbrs.appServicePlan}${appName}-${location}'

var funcCustomField = '${abbrs.functionApp}${appName}-CustomField-${location}'
var funcProcess = '${abbrs.functionApp}${appName}-Intelligence-${location}'
var funcMove = '${abbrs.functionApp}${appName}-Mover-${location}'
var funcQueue = '${abbrs.functionApp}${appName}-Queueing-${location}'
var aiSearchIndexFunctionName = '${abbrs.functionApp}${appName}-AiSearch-${location}'
var askQuestionsFunctionName = '${abbrs.functionApp}${appName}-AskQuestions-${location}'

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
		location: location
		keyVaultName: keyvaultName
		vnetName: vnet
		subnetName: subnet
		myPublicIp: myPublicIp
	}
	dependsOn: [
		keyvault
		networking
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
		aiSearchIndexFunctionName: aiSearchIndexFunctionName
		funcMove: funcMove
		funcQueue: funcQueue
		funcProcess: funcProcess
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

module docIntelligence 'core/documentintelligence.bicep' = {
	name: 'docintelligence'
	scope: rg
	params: {
		docIntelligenceName: formRecognizer
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
		processFunctionName: funcProcess
		customFieldQueueName: customFieldQueueName
		customFieldFunctionName : funcCustomField
		moveFunctionName: funcMove
		queueFunctionName: funcQueue
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
		aiSearchIndexFunctionName: aiSearchIndexFunctionName
		toIndexQueueName: toIndexQueueName
		aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
		openAiEmbeddingModel: azureOpenAIEmbeddingModel
		appInsightsName: appInsightsName
		aiIndexName: aiIndexName
		managedIdentityId: managedIdentity.outputs.id
		azureOpenAiEmbeddingMaxTokens: embeddingMaxTokens
		openAiEndpoint: apiManagement.outputs.gatewayUrl
		openAiChatModel: azureOpenAIChatModel
		askQuestionsFunctionName: askQuestionsFunctionName
		cosmosDbName: cosmosDbName
		cosmosContainerName: cosmosContainerName
	
	}
	dependsOn: [
		storage
		servicebus
		appInsights
		cosmosDb
	]
}

module roleAssigments 'core/roleassignments.bicep' = {
	name: 'roleAssigments'
	scope: rg
	params: {
		docIntelligencePrincipalIds: docIntelligence.outputs.docIntelligencePrincipalIds
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
		keyVaultName: keyvaultName
		location: location
	}
	dependsOn: [
		keyvault
	]
}

module keyvaultSecrets 'core/keyvault-secrets.bicep' = {
	name: 'keyvaultSecrets'
	scope: rg
	params: {
		keyvault: keyvaultName
		docIntelKeyArray: docIntelligence.outputs.docIntellKeyArray
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
		sku: { 
			name: 'Developer'
			capacity: 1
		}
		tags: {
			CreatedBy: currentUserObjectId
		}
	}
	
}

module openAI 'openai/openai.bicep' = [
  for openAIInstance in openAIInstances: {
    name: !empty(openAIInstance.?name)
      ? openAIInstance.name!
      : '${abbrs.openAIService}${appName}-${openAIInstance.suffix}'
    scope: rg
    params: {
			managedIdentityId: managedIdentity.outputs.id
      name: !empty(openAIInstance.?name)
        ? openAIInstance.name!
        : '${abbrs.openAIService}${appName}-${openAIInstance.suffix}'
      location: openAIInstance.location
      deployments: [
        {
          name:  azureOpenAIChatModel
          model: {
            format: 'OpenAI'
            name: azureOpenAIChatModel
            version: chatModelVersion
          }
          sku: {
            name: 'Standard'
            capacity: 49
          }
        }
        {
          name: azureOpenAIEmbeddingModel
          model: {
            format: 'OpenAI'
            name: azureOpenAIEmbeddingModel
            version: embeddingModelVersion
          }
          sku: {
            name: 'Standard'
            capacity: 100
          }
        }
      ]
      keyVaultConfig: {
        keyVaultName: keyvaultName
        primaryKeySecretName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      }
    }
		dependsOn: [
			keyvault
		]
  }

]

module openAIApiKeyNamedValue 'apim/api-management-key-vault-named-value.bicep' = [
  for openAIInstance in openAIInstances: {
    name: 'NV-OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
    scope: rg
    params: {
      name: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      displayName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      apiManagementName: apiManagement.outputs.name
      apiManagementIdentityClientId: managedIdentity.outputs.clientId
      keyVaultSecretUri: '${keyvault.outputs.keyVaultUri}secrets/OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
    }
		dependsOn: [
			roleAssigments
		]
  }
]

// https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management
// GitHub location for API specs: https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference
module openAIApi 'apim/api-management-openai-api.bicep' = {
  name: '${apiManagement.name}-api-openai'
  scope: rg
  params: {
    name: 'openai'
    apiManagementName: apiManagement.outputs.name
    path: '/openai'
    format: 'openapi-link'
    displayName: 'OpenAI'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-02-01/inference.json'
  }
}

module apiSubscription 'apim/api-management-subscription.bicep' = {
  name: '${apiManagement.name}-subscription-openai'
  scope: rg
  params: {
    name: 'openai-sub'
    apiManagementName: apiManagement.outputs.name
    displayName: 'OpenAI API Subscription'
    //scope: '/apis/${openAIApi.outputs.name}'
		scope: '/apis/${openAiApiName}'
		keyVaultName: keyvaultName
  }
	dependsOn: [
		keyvault
		openAIApi

	]
}

module openAIApiBackend 'apim/api-management-backend.bicep' = [
  for (item, index) in openAIInstances: {
    name: '${apiManagement.name}-backend-openai-${item.suffix}'
    scope: rg
    params: {
      name: 'OPENAI${toUpper(item.suffix)}'
      apiManagementName: apiManagement.outputs.name
      url: '${openAI[index].outputs.endpoint}openai'
    }
  }
]

var backends = 	[for (item, index) in openAIInstances: 'OPENAI${toUpper(item.suffix)}']

// Round Robin Load Balancing
module apimRoundRobinLoadBalance 'apim/api-management-round-robin-backend-loadbalance.bicep'  = if(loadBalancingType == 'round-robin') {
	name: '${apiManagement.name}-round-robin-backend-load-balancing'
	scope: rg
	params: {
		apiManagementName: apiManagement.outputs.name
		openaiBackends: backends
	}
	dependsOn: [
		openAIApiBackend

	]
}
module loadRoundRobinBalancingPolicy 'APIM/api-management-round-robin-policy.bicep' = if(loadBalancingType == 'round-robin'){
  name: '${apiManagement.name}-round-robin-policy'
  scope: rg
  params: {
    apiManagementName: apiManagement.outputs.name
    apiName: openAiApiName
    format: 'rawxml'
    value: loadTextContent('APIM/load-balance-pool-policy.xml')
  }
	dependsOn: [
		apimRoundRobinLoadBalance
	]
}

//Priority Load Balancing
module priorityLoadBalancingPolicy 'apim/api-management-priority-policy.bicep' = if(loadBalancingType == 'priority'){
	name: '${apiManagement.name}-priority-policy'
	scope: rg
	params: {
		apiManagementName: apiManagement.outputs.name
		openAiApiName: openAiApiName
		format: 'rawxml'
		policyXml: loadTextContent('APIM/priority-load-balance-policy-main.xml')
	}
	dependsOn: [
		openAIApiBackend
	]
}


module apimLogger 'apim/api-management-logger.bicep' = {
	name: '${apiManagement.name}-logger'
	scope: rg
	params: {
		apiManagementName: apiManagement.outputs.name
		appInsightsName: appInsightsName
	}
	dependsOn: [
		appInsights
	]
}


output resourceGroupName string = resourceGroupName
output processFunctionName string = funcProcess
output moveFunctionName string = funcMove
output queueFunctionName string = funcQueue	
output aiSearchIndexFunctionName string = aiSearchIndexFunctionName
output questionsFunctionName string = askQuestionsFunctionName
output customFieldFunctionName string = funcCustomField


output openAINames array = [for i in range(0, length(openAIInstances)): openAI[i].outputs.name]
output openAiChatModel string = azureOpenAIChatModel
output openAiEmbeddingModel string = azureOpenAIEmbeddingModel
output apimName string = apiManagement.outputs.name

