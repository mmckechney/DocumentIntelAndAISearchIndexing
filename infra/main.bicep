
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

param includeGeneralIndex bool = true

param apiManagementPublisherEmail string
param apiManagementPublisherName string

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

var abbrs = loadJsonContent('./abbreviations.json')
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
var funcAppPlan = '${abbrs.appServicePlan}${appName}-${location}'
var funcProcess = '${abbrs.functionApp}${appName}-Intelligence-${location}'
var funcMove = '${abbrs.functionApp}${appName}-Mover-${location}'
var funcQueue = '${abbrs.functionApp}${appName}-Queueing-${location}'
var aiSearchIndexFunctionName = '${abbrs.functionApp}${appName}-AiSearch-${location}'
var keyvaultName = '${abbrs.keyVault}${appName}-${location}'

var aiSearchName = '${abbrs.aiSearch}${appNameLc}-demo-${location}'
var appInsightsName = '${abbrs.applicationInsights}${appName}-${location}'
var logAnalyticsName = '${abbrs.logAnalyticsWorkspace}${appName}-${location}'
var managedIdentityName = '${abbrs.managedIdentity}${appName}-${location}'
var apiManagementName = '${abbrs.apiManagementService}${appName}-${location}'

var documentStorageContainer = 'documents'
var processResultsContainer = 'processresults'
var completedContainer = 'completed'

var formQueueName = 'docqueue'
var processedQueueName = 'processedqueue'
var toIndexQueueName = 'toindexqueue'

var openAiApiName = 'openai'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
}

module managedIdentity 'managed-identity.bicep' = {
	name: 'managedIdentity'
	scope: resourceGroup(resourceGroupName)
	params: {
		name: managedIdentityName
		location: location
	}
	dependsOn: [
		rg
	]
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

module functions 'Functions/functions.bicep' = {
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
		openAiEmbeddingModel: azureOpenAIEmbeddingModel
		appInsightsName: appInsightsName
		includeGeneralIndex: includeGeneralIndex
		managedIdentityId: managedIdentity.outputs.id
		azureOpenAiEmbeddingMaxTokens: embeddingMaxTokens
		openAiEndpoint: apiManagement.outputs.gatewayUrl
		
	}
	dependsOn: [
		rg
		networking
		storage
		keyvault
		servicebus
		appInsights
		managedIdentity
		apiManagement
	]
}

module roleAssigments 'roleassignments.bicep' = {
	name: 'roleAssigments'
	scope: resourceGroup(resourceGroupName)
	params: {
		docIntelligencePrincipalIds: docIntelligence.outputs.docIntelligencePrincipalIds
		userAssignedManagedIdentityPrincipalId: managedIdentity.outputs.principalId
		currentUserObjectId : currentUserObjectId
		functionPrincipalIds: functions.outputs.systemAssignedIdentities
		apimSystemAssignedIdentityPrincipalId: apiManagement.outputs.identity
	}
	dependsOn: [
		rg
		managedIdentity
		functions
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

module keyvaultSecrets 'keyvault-secrets.bicep' = {
	name: 'keyvaultSecrets'
	scope: resourceGroup(resourceGroupName)
	params: {
		keyvault: keyvaultName
		docIntelKeyArray: docIntelligence.outputs.docIntellKeyArray
	}
	dependsOn: [
		rg
		keyvault
		docIntelligence
	]
}

module apiManagement 'APIM/api-management.bicep' = {
	name: 'apiManagement'
	scope: resourceGroup(resourceGroupName)
	params: {
		name: apiManagementName
		location: location
		apiManagementIdentityId: managedIdentity.outputs.id
		publisherEmail: apiManagementPublisherEmail
		publisherName: apiManagementPublisherName
		sku: { 
			name: 'Developer'
			capacity: 1
		}
		tags: {
			CreatedBy: currentUserObjectId
		}
	}
	dependsOn: [
		rg
	]
}

module openAI 'OpenAI/openai.bicep' = [
  for openAIInstance in openAIInstances: {
    name: !empty(openAIInstance.name)
      ? openAIInstance.name!
      : '${abbrs.openAIService}${appName}-${openAIInstance.suffix}'
    scope: resourceGroup(resourceGroupName)
    params: {
			managedIdentityId: managedIdentity.outputs.id
      name: !empty(openAIInstance.name)
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
            capacity: 1
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
            capacity: 1
          }
        }
      ]
      keyVaultConfig: {
        keyVaultName: keyvaultName
        primaryKeySecretName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      }
    }
		dependsOn: [
			rg
			keyvault
		]
  }

]

module openAIApiKeyNamedValue 'APIM/api-management-key-vault-named-value.bicep' = [
  for openAIInstance in openAIInstances: {
    name: 'NV-OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
    scope: resourceGroup(resourceGroupName)
    params: {
      name: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      displayName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      apiManagementName: apiManagement.outputs.name
      apiManagementIdentityClientId: managedIdentity.outputs.clientId
      keyVaultSecretUri: '${keyvault.outputs.keyVaultUri}secrets/OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
    }
		dependsOn: [
			rg
			roleAssigments
		]
  }
]

// https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management
module openAIApi 'APIM/api-management-openai-api.bicep' = {
  name: '${apiManagement.name}-api-openai'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'openai'
    apiManagementName: apiManagement.outputs.name
    path: '/openai'
    format: 'openapi-link'
    displayName: 'OpenAI'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-03-15-preview/inference.json'
  }
}

module apiSubscription 'APIM/api-management-subscription.bicep' = {
  name: '${apiManagement.name}-subscription-openai'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'openai-sub'
    apiManagementName: apiManagement.outputs.name
    displayName: 'OpenAI API Subscription'
    //scope: '/apis/${openAIApi.outputs.name}'
		scope: '/apis/${openAiApiName}'
		keyVaultName: keyvaultName
  }
	dependsOn: [
		rg
		keyvault
		openAIApi

	]
}

module openAIApiBackend 'APIM/api-management-backend.bicep' = [
  for (item, index) in openAIInstances: {
    name: '${apiManagement.name}-backend-openai-${item.suffix}'
    scope: resourceGroup(resourceGroupName)
    params: {
      name: 'OPENAI${toUpper(item.suffix)}'
      apiManagementName: apiManagement.outputs.name
      url: '${openAI[index].outputs.endpoint}openai'
    }
  }
]

var backends = 	[for (item, index) in openAIInstances: 'OPENAI${toUpper(item.suffix)}']

// Round Robin Load Balancing
module apimRoundRobinLoadBalance 'APIM/api-management-round-robin-backend-loadbalance.bicep'  = if(loadBalancingType == 'round-robin') {
	name: '${apiManagement.name}-round-robin-backend-load-balancing'
	scope: resourceGroup(resourceGroupName)
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
  scope: resourceGroup(resourceGroupName)
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
module priorityLoadBalancingPolicy 'APIM/api-management-priority-policy.bicep' = if(loadBalancingType == 'priority'){
	name: '${apiManagement.name}-priority-policy'
	scope: resourceGroup(resourceGroupName)
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


module apimLogger 'APIM/api-management-logger.bicep' = {
	name: '${apiManagement.name}-logger'
	scope: resourceGroup(resourceGroupName)
	params: {
		apiManagementName: apiManagement.outputs.name
		appInsightsName: appInsightsName
	}
	dependsOn: [
		appInsights
		apiManagement
	]
}


output resourceGroupName string = resourceGroupName
output processFunctionName string = funcProcess
output moveFunctionName string = funcMove
output queueFunctionName string = funcQueue	
output aiSearchIndexFunctionName string = aiSearchIndexFunctionName


output openAINames array = [for i in range(0, length(openAIInstances)): openAI[i].outputs.name]
output openAiChatModel string = azureOpenAIChatModel
output openAiEmbeddingModel string = azureOpenAIEmbeddingModel
output apimName string = apiManagement.outputs.name

