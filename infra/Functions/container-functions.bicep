param location string = resourceGroup().location
param processFunctionName string
param aiSearchIndexFunctionName string
param customFieldFunctionName string
param moveFunctionName string
param queueFunctionName string
param askQuestionsFunctionName string
param containerAppEnvironmentName string
param containerRegistryName string
param aiSearchEndpoint string
param openAiEndpoint string
param azureOpenAiEmbeddingMaxTokens int = 8091
param managedIdentityId string
param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param aiIndexName string
param openAiChatModel string
param openAiEmbeddingModel string
param cosmosDbName string
param cosmosContainerName string
param cosmosDbAccountName string
param appInsightsName string
param keyVaultUri string
param formStorageAcctName string
param functionStorageAcctName string
param moveQueueName string
param serviceBusNs string
param customFieldQueueName string
param docQueueName string
param toIndexQueueName string

var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource funcStorageAcct 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: functionStorageAcctName
}


// var cosmosKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.COSMOS_CONNECTION}/)'
var sbConnKvReference = '${keyVaultUri}secrets/${keyVaultKeys.SERVICEBUS_CONNECTION}'
var aiSearchKvReference = '${keyVaultUri}secrets/${keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY}'
var apimSubscriptionKeyKvReference = '${keyVaultUri}secrets/${keyVaultKeys.APIM_SUBSCRIPTION_KEY}'
var storageKvReference = '${keyVaultUri}secrets/${keyVaultKeys.STORAGE_CONNECTION}'
var frEndpointKvReference = '${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT}'
var frKeyKvReference = '${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
  name: cosmosDbAccountName
}

// Define container app configurations for each function
var containerApps = [
  {
    name: processFunctionName
    image: '${containerRegistryName}.azurecr.io/document-intelligence-function:latest'
    isExternalIngress: false
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: true
    queueName: docQueueName
    appDllName: 'DocumentIntelligence.dll'
    
  }
  {
    name: aiSearchIndexFunctionName
    image: '${containerRegistryName}.azurecr.io/ai-search-indexing-function:latest'
    isExternalIngress: false
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: true
    queueName: toIndexQueueName
    appDllName: 'AiSearchIndexFunction.dll'
  }
  {
    name: customFieldFunctionName
    image: '${containerRegistryName}.azurecr.io/custom-field-extraction-function:latest'
    isExternalIngress: false
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: true
    queueName: customFieldQueueName
    appDllName: 'CustomFieldExtractionFunction.dll'
  }
  {
    name: moveFunctionName
    image: '${containerRegistryName}.azurecr.io/processed-file-mover-function:latest'
    isExternalIngress: false
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: true
    queueName: moveQueueName
    appDllName: 'ProcessedFileMover.dll'
  }
  {
    name: queueFunctionName
    image: '${containerRegistryName}.azurecr.io/document-queueing-function:latest'
    isExternalIngress: true
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: false
    queueName: moveQueueName
    appDllName: 'DocumentQueueingFunction.dll'
  }
  {
    name: askQuestionsFunctionName
    image: '${containerRegistryName}.azurecr.io/document-questions-function:latest'
    isExternalIngress: true
    containerPort: 80
    minReplicas: 1
    maxReplicas: 5
    cpuCore: '0.5'
    memorySize: '1.0Gi'
    env: []
    serviceBusNamespace: serviceBusNs
    useServiceBusScaleRule: false
    queueName: moveQueueName
    appDllName: 'DocumentQuestionsFunction.dll'
  }
]

var sharedKvSecrets =[
  {
    name: toLower(keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY)
    keyVaultUrl: aiSearchKvReference
    identity: managedIdentityId
  }
  {
    name: toLower(keyVaultKeys.APIM_SUBSCRIPTION_KEY)
    keyVaultUrl: apimSubscriptionKeyKvReference
    identity: managedIdentityId
  }
  {
    name: toLower(keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT)
    keyVaultUrl: frEndpointKvReference
    identity: managedIdentityId
  }
  {
    name: toLower(keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY)
    keyVaultUrl: frKeyKvReference
    identity: managedIdentityId
  }
  {
    name: toLower(keyVaultKeys.STORAGE_CONNECTION)
    keyVaultUrl: storageKvReference
    identity: managedIdentityId
  }
  {
    name: toLower(keyVaultKeys.SERVICEBUS_CONNECTION)
    keyVaultUrl: sbConnKvReference
    identity: managedIdentityId
  }
]

var sharedKvSecretRefs =[
  {
    name: configKeys.AZURE_AISEARCH_ADMIN_KEY
    secretRef: toLower(keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY)
  }
  { 
    name: configKeys.APIM_SUBSCRIPTION_KEY
    secretRef: toLower(keyVaultKeys.APIM_SUBSCRIPTION_KEY)
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_ENDPOINT
    secretRef: toLower(keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT)
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_KEY
    secretRef: toLower(keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY)
  }
  {
    name: configKeys.STORAGE_CONNECTION
    secretRef: toLower(keyVaultKeys.STORAGE_CONNECTION)
  }
  {
    name: configKeys.SERVICEBUS_CONNECTION
    secretRef: toLower(keyVaultKeys.SERVICEBUS_CONNECTION)
  }
]
var sharedConfiguration = [
  {
    name: configKeys.COSMOS_DB_NAME
    value: cosmosDbName
  }
  {
    name: configKeys.COSMOS_CONTAINER_NAME
    value: cosmosContainerName
  }
  {
    name: configKeys.COSMOS_ENDPOINT
    value: cosmosDbAccount.properties.documentEndpoint
  }
  {
    name: configKeys.STORAGE_ACCOUNT_NAME
    value: formStorageAcctName
  }
  {
    name: configKeys.STORAGE_SOURCE_CONTAINER_NAME
    value: documentStorageContainer
  }
  {
    name: configKeys.STORAGE_PROCESS_RESULTS_CONTAINER_NAME
    value: processResultsContainer
  }
  {
    name: configKeys.STORAGE_COMPLETED_CONTAINER_NAME
    value: completedContainer
  }
  {
    name: 'ServiceBusConnection__fullyQualifiedNamespace' 
    value: '${serviceBusNs}.servicebus.windows.net' 
  }
  {
    name: configKeys.SERVICEBUS_NAMESPACE_NAME
    value: serviceBusNs
  }
  {
    name: configKeys.SERVICEBUS_DOC_QUEUE_NAME
    value: docQueueName
  }
  {
    name: configKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME
    value: customFieldQueueName
  }
  {
    name: configKeys.SERVICEBUS_TOINDEX_QUEUE_NAME
    value: toIndexQueueName
  }
  {
    name: configKeys.SERVICEBUS_MOVE_QUEUE_NAME
    value: moveQueueName
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAcctName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(funcStorageAcct.id, funcStorageAcct.apiVersion).keys[0].value}'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet-isolated'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
  {
    name: configKeys.AZURE_AISEARCH_ENDPOINT
    value: aiSearchEndpoint
  }

  {
    name: configKeys.AZURE_AISEARCH_INDEX_NAME
    value: aiIndexName
  }
  {
    name: configKeys.AZURE_OPENAI_ENDPOINT
    value: openAiEndpoint
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_MODEL
    value: openAiEmbeddingModel
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_DEPLOYMENT
    value: openAiEmbeddingModel
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_MAXTOKENS
    value: string(azureOpenAiEmbeddingMaxTokens)
  }
  {
    name: configKeys.AZURE_OPENAI_CHAT_MODEL
    value: openAiChatModel
  }
  {
    name: configKeys.AZURE_OPENAI_CHAT_DEPLOYMENT
    value: openAiChatModel
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_MODEL_NAME
    value: 'prebuilt-layout'
  }
 
]

module containerAppFunctions '../core/container-app-functions.bicep' = {
  name: 'containerAppFunctions'
  params: {
    location: location
    containerApps: containerApps
    containerAppEnvironmentName: containerAppEnvironmentName
    containerRegistryName: containerRegistryName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    sharedKvSecrets: sharedKvSecrets
    sharedKvSecretRefs : sharedKvSecretRefs

  }
}

