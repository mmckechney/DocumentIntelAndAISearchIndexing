import * as customTypes from '../constants/customTypes.bicep'

param funcAppPlan string
param location string = resourceGroup().location
param functionValues customTypes.functionValue[]
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param moveQueueName string
param serviceBusNs string
param formStorageAcctName string
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
param cosmosDbName string
param cosmosContainerName string
param funcAppPlanSku string

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
var frEndpointKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT}/)'
var frKeyKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY}/)'

resource appInsights 'Microsoft.Insights/components@2020-02-02'existing = {
  name: appInsightsName
}

module functionAppPlan 'appplan.bicep' = {
  name: funcAppPlan
  params: {
    location: location
    funcAppPlan: funcAppPlan
    funcAppPlanSku: funcAppPlanSku
  }
}


module function 'function.bicep' = [for functionValue in functionValues: {
  name: functionValue.name
  params: {
    location: location
    functionName: functionValue.name
    functionTag : functionValue.tag
    functionSubnetId: functionSubnetId
    managedIdentityId: managedIdentityId
    funcAppPlanId: functionAppPlan.outputs.functionAppPlanId
    sharedConfiguration: sharedConfiguration
  }
}]



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
    name: configKeys.SERVICEBUS_CONNECTION
    value: sbConnKvReference
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
]

output systemAssignedIdentities array = [for i in range(0, length(functionValues)): function[i].outputs.systemAssignedIdentity]

