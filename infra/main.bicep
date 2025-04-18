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
// var appNameLc = toLower(appName)

var resourceGroupName = '${abbrs.resourceGroup}${appName}-${location}'
// var serviceBusNs = '${abbrs.serviceBusNamespace}${appName}-${location}'
// var formStorageAcct = '${abbrs.storageAccount}${appNameLc}${location}'
// var funcStorageAcct = '${abbrs.storageAccount}${appNameLc}func${location}'
// var formRecognizer = '${abbrs.documentIntelligence}${appName}-${location}'

// var vnet = '${abbrs.virtualNetwork}${appName}-${location}'
// var subnet = '${abbrs.virtualNetworkSubnet}${appName}-${location}'
// var nsg = '${abbrs.networkSecurityGroup}${appName}-${location}'
// var containerAppSubnet = '${abbrs.virtualNetworkSubnet}${appName}-ca-${location}'
// var apimsubnet = '${abbrs.virtualNetworkSubnet}${appName}-apim-${location}'

// var funcCustomField = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Custom-${location}')
// var funcProcess = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Intell-${location}')
// var funcMove = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Mover-${location}')
// var funcQueue = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Queueing-${location}')
// var aiSearchIndexFunctionName = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-AiSearch-${location}')
// var askQuestionsFunctionName = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Ask-${location}')

// var keyvaultName = '${abbrs.keyVault}${appName}-${location}'

// var aiSearchName = '${abbrs.aiSearch}${appNameLc}-demo-${location}'
// var appInsightsName = '${abbrs.applicationInsights}${appName}-${location}'
// var logAnalyticsName = '${abbrs.logAnalyticsWorkspace}${appName}-${location}'
// var managedIdentityName = '${abbrs.managedIdentity}${appName}-${location}'
// var apiManagementName = '${abbrs.apiManagementService}${appName}-${location}'

// var cosmosDbName = 'documentIndexing'
// var cosmosContainerName = 'processTracker'
// var cosmosDbAccountName = toLower('${abbrs.cosmosDBNoSQL}${appName}-${location}')

// var documentStorageContainer = 'documents'
// var processResultsContainer = 'processresults'
// var completedContainer = 'completed'

// var customFieldQueueName = 'customfieldqueue'
// var docQueueName = 'docqueue'
// var moveQueueName = 'movequeue'
// var toIndexQueueName = 'toindexqueue'

// var openAiApiName = 'openai'

// var containerAppEnvName = '${abbrs.containerAppsEnvironment}${appName}-${location}'
// var containerRegistryName = toLower('${abbrs.containerRegistry}${appNameLc}${location}')

module names './resourcenames.bicep' = {
	name: 'names'
	params: {
		appName: appName
		location: location
	}
}
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
}

module managedIdentity 'core/managed-identity.bicep' =  {
	name: 'managedIdentity'
	scope: rg
	params: {
		location: location
		name: names.outputs.managedIdentityName
	}
}

module networkSecurityGroup 'core/networksecuritygroup.bicep' = {
	name: 'networkSecurityGroup'
	scope: rg
	params: {
		location: location
		myPublicIp: myPublicIp
		nsg: names.outputs.nsg
	}
}

module cosmosDb 'core/cosmos.bicep' = {
	name: 'cosmosDb'
	scope: rg
	params: {
		apimSubnetId: networking.outputs.apimSubnetId
		cosmosContainerName: names.outputs.cosmosContainerName
		cosmosDbAccountName: names.outputs.cosmosDbAccountName
		databaseName: names.outputs.cosmosDbName
		containerAppSubnetId: networking.outputs.containerAppSubnetId
		keyVaultName: names.outputs.keyvaultName
		location: location
		myPublicIp: myPublicIp
		subnetName: names.outputs.subnet
		vnetName: names.outputs.vnet
	}
	dependsOn: [
		keyvault
	]
}

module networking 'core/networking.bicep' = {
	name: 'networking'
	scope: rg
	params: {
		apimsubnet: names.outputs.apimsubnet
		containerAppSubnet: names.outputs.containerAppSubnet
		location: location
		nsg: names.outputs.nsg
		subnet: names.outputs.subnet
		vnet: names.outputs.vnet
	}
	dependsOn: [
		networkSecurityGroup
	]
}

module appInsights 'core/appinsights.bicep' = {
	name: 'appInsights'
	scope: rg
	params: {
		aiSearchIndexFunctionName: names.outputs.aiSearchIndexFunctionName
		appInsightsName: names.outputs.appInsightsName
		funcMove: names.outputs.funcMove
		funcProcess: names.outputs.funcProcess
		funcQueue: names.outputs.funcQueue
		location: location
		logAnalyticsName: names.outputs.logAnalyticsName
	}
}

module storage 'core/storage.bicep' = {
	name: 'storage'
	scope: rg
	params: {
		completedContainer: names.outputs.completedContainer
		documentStorageContainer: names.outputs.documentStorageContainer
		formStorageAcct: names.outputs.formStorageAcct
		funcStorageAcct: names.outputs.funcStorageAcct
		keyVaultName: names.outputs.keyvaultName
		location: location
		myPublicIp: myPublicIp
		processResultsContainer: names.outputs.processResultsContainer
		subnetIds: networking.outputs.storageSubnetIds
	}
	dependsOn: [
		keyvault
	]
}

module docIntelligence 'core/documentintelligence.bicep' = {
	name: 'docintelligence'
	scope: rg
	params: {
		docIntelligenceInstanceCount: docIntelligenceInstanceCount
		docIntelligenceName: names.outputs.formRecognizer
		keyVaultName: names.outputs.keyvaultName
		location: location
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
		customFieldQueueName: names.outputs.customFieldQueueName
		docQueueName: names.outputs.docQueueName
		keyVaultName: names.outputs.keyvaultName
		location: location
		moveQueueName: names.outputs.moveQueueName
		serviceBusNs: names.outputs.serviceBusNs
		serviceBusSku: serviceBusSku
		subnetName: names.outputs.containerAppSubnet
		toIndexQueueName: names.outputs.toIndexQueueName
		vnetName: names.outputs.vnet
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
		keyVaultName: names.outputs.keyvaultName
		location: location
	}
	dependsOn: [
		networking
	]
}



module containerAppEnvironment 'core/container-app-environment.bicep' = {
  name: 'containerAppEnvironment'
  scope: rg
  params: {
    location: location
    containerAppEnvName: names.outputs.containerAppEnvName
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsName
    vnetName: names.outputs.vnet
    subnetName: names.outputs.containerAppSubnet
    minReplicas: 0
    maxReplicas: 10
  }
  dependsOn: [
    appInsights
    networking
  ]
}

// Comment out original functions module and replace with container-based version
// module functions 'functions/functions.bicep' = {
// 	name: 'functions'
// 	scope: rg
// 	params: {
// 		aiIndexName: aiIndexName
// 		aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
// 		aiSearchIndexFunctionName: names.outputs.aiSearchIndexFunctionName
// 		appInsightsName: names.outputs.appInsightsName
// 		askQuestionsFunctionName: names.outputs.askQuestionsFunctionName
// 		azureOpenAiEmbeddingMaxTokens: embeddingMaxTokens
// 		completedContainer: names.outputs.completedContainer
// 		cosmosContainerName: names.outputs.cosmosContainerName
// 		cosmosDbAccountName: names.outputs.cosmosDbAccountName
// 		cosmosDbName: names.outputs.cosmosDbName
// 		customFieldFunctionName: names.outputs.funcCustomField
// 		customFieldQueueName: names.outputs.customFieldQueueName
// 		docQueueName: names.outputs.docQueueName
// 		documentStorageContainer: names.outputs.documentStorageContainer
// 		formStorageAcctName: names.outputs.formStorageAcct
// 		functionStorageAcctName: names.outputs.funcStorageAcct
// 		containerAppSubnetId: networking.outputs.containerAppSubnetId
// 		keyVaultUri: keyvault.outputs.keyVaultUri
// 		location: location
// 		managedIdentityId:managedIdentity.outputs.id
// 		moveFunctionName: names.outputs.funcMove
// 		moveQueueName: names.outputs.moveQueueName
// 		openAiChatModel: azureOpenAIChatModel
// 		openAiEmbeddingModel: azureOpenAIEmbeddingModel
// 		openAiEndpoint: apiManagement.outputs.gatewayUrl
// 		processFunctionName: names.outputs.funcProcess
// 		processResultsContainer: names.outputs.processResultsContainer
// 		queueFunctionName: names.outputs.funcQueue
// 		serviceBusNs: names.outputs.serviceBusNs
// 		toIndexQueueName: names.outputs.toIndexQueueName
// 		containerAppEnvironmentId: containerAppEnvironment.outputs.id


// 	}
// 	dependsOn: [
// 		storage
// 		servicebus
// 		appInsights
// 		cosmosDb
// 	]
// }

// Replace with containerized functions
module containerFunctions 'functions/container-functions.bicep' = {
  name: 'containerFunctions'
  scope: rg
  params: {
    location: location
    processFunctionName: names.outputs.funcProcess
    aiSearchIndexFunctionName: names.outputs.aiSearchIndexFunctionName
    customFieldFunctionName: names.outputs.funcCustomField
    moveFunctionName: names.outputs.funcMove
    queueFunctionName: names.outputs.funcQueue
    askQuestionsFunctionName: names.outputs.askQuestionsFunctionName
    containerAppEnvironmentName: containerAppEnvironment.outputs.name
    containerRegistryName: names.outputs.containerRegistryName
    aiSearchEndpoint: aiSearch.outputs.aiSearchEndpoint
    openAiEndpoint: apiManagement.outputs.gatewayUrl
    azureOpenAiEmbeddingMaxTokens: embeddingMaxTokens
    managedIdentityId: managedIdentity.outputs.id
		documentStorageContainer: names.outputs.documentStorageContainer
    processResultsContainer: names.outputs.processResultsContainer
    completedContainer: names.outputs.completedContainer
    aiIndexName: aiIndexName
    openAiChatModel: azureOpenAIChatModel
    openAiEmbeddingModel: azureOpenAIEmbeddingModel
    cosmosDbName: names.outputs.cosmosDbName
    cosmosContainerName: names.outputs.cosmosContainerName
    cosmosDbAccountName: names.outputs.cosmosDbAccountName
    appInsightsName: names.outputs.appInsightsName
    keyVaultUri: keyvault.outputs.keyVaultUri
    formStorageAcctName: names.outputs.formStorageAcct
		functionStorageAcctName: names.outputs.funcStorageAcct
    moveQueueName: names.outputs.moveQueueName
    serviceBusNs: names.outputs.serviceBusNs
    customFieldQueueName: names.outputs.customFieldQueueName
    docQueueName: names.outputs.docQueueName
    toIndexQueueName: names.outputs.toIndexQueueName
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
		apimSystemAssignedIdentityPrincipalId: apiManagement.outputs.systemIdentity
		cosmosDbAccountName: names.outputs.cosmosDbAccountName
		currentUserObjectId: {id:currentUserObjectId, name: 'CurrentUser'}
		docIntelligencePrincipalIds: docIntelligence.outputs.docIntelligencePrincipalIds
		userAssignedManagedIdentityPrincipalId:  managedIdentity.outputs.principalId 
		containerRegistryName: names.outputs.containerRegistryName
	}
	dependsOn: [
		cosmosDb

	]
}

module aiSearch 'core/aisearch.bicep' = {
	name: 'aiSearch'
	scope: rg
	params: {
		aiSearchName: names.outputs.aiSearchName
		keyVaultName: names.outputs.keyvaultName
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
		docIntelKeyArray: docIntelligence.outputs.docIntellKeyArray
		keyvault: names.outputs.keyvaultName
	}
	dependsOn: [
		keyvault
	]
}

module apiManagement 'apim/api-management.bicep' = {
	name: 'apiManagement'
	scope: rg
	params: {
		apiManagementIdentityId:managedIdentity.outputs.id
		location: location
		name: names.outputs.apiManagementName
		publisherEmail: apiManagementPublisherEmail
		publisherName: apiManagementPublisherName
		sku: { 
			capacity: 1
			name: 'Developer'
		}
		subnetId: networking.outputs.apimSubnetId
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
      deployments: [
        {
          model: {
            format: 'OpenAI'
            name: azureOpenAIChatModel
            version: chatModelVersion
          }
          name: azureOpenAIChatModel
          sku: {
            capacity: 49
            name: 'Standard'
          }
        }
        {
          model: {
            format: 'OpenAI'
            name: azureOpenAIEmbeddingModel
            version: embeddingModelVersion
          }
          name: azureOpenAIEmbeddingModel
          sku: {
            capacity: 100
            name: 'Standard'
          }
        }
      ]
      keyVaultConfig: {
        keyVaultName: names.outputs.keyvaultName
        primaryKeySecretName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      }
      location: openAIInstance.location
      managedIdentityId:  managedIdentity.outputs.id
      name: !empty(openAIInstance.?name)
        ? openAIInstance.name!
        : '${abbrs.openAIService}${appName}-${openAIInstance.suffix}'
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
      apiManagementIdentityClientId:  managedIdentity.outputs.clientId 
      apiManagementName: apiManagement.outputs.name
      displayName: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      keyVaultSecretUri: '${keyvault.outputs.keyVaultUri}secrets/OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'
      name: 'OPENAI-API-KEY-${toUpper(openAIInstance.suffix)}'

    }
    dependsOn: [
      roleAssigments
    ]
  }
]

module openAIApi 'apim/api-management-openai-api.bicep' = {
  name: '${apiManagement.name}-api-openai'
  scope: rg
  params: {
    apiManagementName: apiManagement.outputs.name
    displayName: 'OpenAI'
    format: 'openapi-link'
    name: 'openai'
    path: '/openai'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-02-01/inference.json'
  }
}

module apiSubscription 'apim/api-management-subscription.bicep' = {
  name: '${apiManagement.name}-subscription-openai'
  scope: rg
  params: {
    apiManagementName: apiManagement.outputs.name
    displayName: 'OpenAI API Subscription'
    keyVaultName: names.outputs.keyvaultName
    name: 'openai-sub'
    scope: '/apis/${names.outputs.openAiApiName}'
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
      apiManagementName: apiManagement.outputs.name
      name: 'OPENAI${toUpper(item.suffix)}'
      url: '${openAI[index].outputs.endpoint}openai'
    }
  }
]

var backends = 	[for (item, index) in openAIInstances: 'OPENAI${toUpper(item.suffix)}']

// Round Robin Load Balancing
module apimRoundRobinLoadBalance 'apim/api-management-round-robin-backend-loadbalance.bicep' = if(loadBalancingType == 'round-robin') {
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
    apiName: names.outputs.openAiApiName
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
		format: 'rawxml'
		openAiApiName: names.outputs.openAiApiName
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
		appInsightsName: names.outputs.appInsightsName
	}
	dependsOn: [
		appInsights
	]
}

module keyVaultAccessPolicy 'core/keyvault-accesspolicy.bicep' =  {
	name: 'keyVaultAccessPolicy'
	scope: rg
	params: {
		apimSystemIdentityId: apiManagement.outputs.systemIdentity
		currentUserObjectId: {id: currentUserObjectId, name: 'CurrentUser'}
		userAssignedManagedIdentity:  managedIdentity.outputs.principalId 
		keyVaultName: names.outputs.keyvaultName
	}
}

output resourceGroupName string = resourceGroupName
output processFunctionName string = names.outputs.funcProcess
output moveFunctionName string = names.outputs.funcMove
output queueFunctionName string = names.outputs.funcQueue	
output aiSearchIndexFunctionName string = names.outputs.aiSearchIndexFunctionName
output questionsFunctionName string = names.outputs.askQuestionsFunctionName
output customFieldFunctionName string = names.outputs.funcCustomField

output openAINames array = [for i in range(0, length(openAIInstances)): openAI[i].outputs.name]
output openAiChatModel string = azureOpenAIChatModel
output openAiEmbeddingModel string = azureOpenAIEmbeddingModel
output apimName string = apiManagement.outputs.name

