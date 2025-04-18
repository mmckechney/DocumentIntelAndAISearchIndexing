param containerAppEnvironmentId string
param location string = resourceGroup().location
param processFunctionName string
param aiSearchIndexFunctionName string
param customFieldFunctionName string
param containerAppSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param moveQueueName string
param serviceBusNs string
param formStorageAcctName string
param moveFunctionName string
param queueFunctionName string
param customFieldQueueName string
param docQueueName string
param toIndexQueueName string
param openAiEmbeddingModel string
param aiSearchEndpoint string
param openAiEndpoint string
param azureOpenAiEmbeddingMaxTokens int = 8091
param managedIdentityId string
param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param appInsightsName string
param aiIndexName string
param openAiChatModel string
param askQuestionsFunctionName string
param cosmosDbName string
param cosmosContainerName string
param cosmosDbAccountName string


var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource funcStorageAcct 'Microsoft.Storage/storageAccounts@2021-04-01'existing = {
  name: functionStorageAcctName
}
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAcct.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageAcct.listKeys().keys[0].value}'
var cosmosKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.COSMOS_CONNECTION}/)'
var sbConnKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.SERVICEBUS_CONNECTION}/)'
var aiSearchKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY}/)'
var apimSubscriptionKeyKvReference ='@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.APIM_SUBSCRIPTION_KEY}/)' 
var storageKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.STORAGE_CONNECTION}/)'
var frEndpointKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT}/)'
var frKeyKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY}/)'

resource appInsights 'Microsoft.Insights/components@2020-02-02'existing = {
  name: appInsightsName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
  name: cosmosDbAccountName
}


module processFunction 'function-process.bicep' = {
  name: processFunctionName
  params: {
    location: location
    processFunctionName: processFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }

}


module customFieldFunction 'function-customfield.bicep' = {
  name: customFieldFunctionName
  params: {
    location: location
    customFieldFunctionName: customFieldFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }

}

module aiSearchFunction 'function-aisearch.bicep' = {
  name: aiSearchIndexFunctionName
  params: {
    location: location
    aiSearchIndexFunctionName: aiSearchIndexFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }

}

module moveFunction 'function-move.bicep' = {
  name: moveFunctionName
  params: {
    location: location
    moveFunctionName: moveFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }

}

module queueFunction 'functions-queueing.bicep' = {
  name: queueFunctionName
  params: {
    location: location
    queueFunctionName: queueFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }
 
}

module askQuestions 'function-askquestions.bicep' = {
  name: askQuestionsFunctionName
  params: {
    location: location
    askQuestionsFunctionName: askQuestionsFunctionName
    managedIdentityId: managedIdentityId
    sharedConfiguration: sharedConfiguration
    containerAppEnvironmentId: containerAppEnvironmentId
    containerAppSubnetId: containerAppSubnetId
  }
}

var sharedConfiguration = [
  {
    name: configKeys.COSMOS_CONNECTION
    value: cosmosKvReference
  }
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
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnectionString 
  }
  // {
  //   name: useManagedIdentity ? 'AzureWebJobsStorage__accountName' : 'AzureWebJobsStorage'
  //   value: useManagedIdentity ? functionStorageAcctName : storageConnectionString
  // }
   {
    name: 'AzureWebJobsStorage'
    value: storageConnectionString
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
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
  // Add Linux-specific app settings
  {
    name: 'WEBSITE_USE_PLACEHOLDER'
    value: '0'
  }
  // Add SCM_DO_BUILD_DURING_DEPLOYMENT to disable build during deployment
  {
    name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
    value: 'false'
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
    name: configKeys.AZURE_AISEARCH_ADMIN_KEY
    value: aiSearchKvReference  
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
    name: configKeys.APIM_SUBSCRIPTION_KEY
    value: apimSubscriptionKeyKvReference
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_MODEL_NAME
    value: 'prebuilt-layout'
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_ENDPOINT
    value: frEndpointKvReference
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_KEY
    value: frKeyKvReference
  }
  {
    name: configKeys.STORAGE_CONNECTION
    value: storageKvReference
  }
]

// Output the function app names and system assigned identitiesVAR 
output systemAssignedIdentities array = [
  {
    id : processFunction.outputs.systemAssignedIdentity
    name: 'ProcessFunction-SystemAssignedIdentity'
  }
  {
    id : aiSearchFunction.outputs.systemAssignedIdentity
    name: 'AiSearchFunction-SystemAssignedIdentity'
  }
  {
    id : moveFunction.outputs.systemAssignedIdentity
    name: 'MoveFunction-SystemAssignedIdentity'
  }
  {
    id : queueFunction.outputs.systemAssignedIdentity
    name: 'QueueFunction-SystemAssignedIdentity'
  }
  {
    id : askQuestions.outputs.systemAssignedIdentity
    name: 'AskQuestionsFunction-SystemAssignedIdentity'
  }
  {
    id : customFieldFunction.outputs.systemAssignedIdentity
    name: 'CustomFieldFunction-SystemAssignedIdentity'
  }

]
