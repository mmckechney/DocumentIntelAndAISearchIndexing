param funcAppPlan string
param location string = resourceGroup().location
param aiSearchIndexFunctionName string
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param serviceBusNs string
param formStorageAcctName string
param toIndexQueueName string
param openAiEmbeddingModel string
param aiSearchEndpoint string
param openAiEndpoint string
param azureOpenAiEmbeddingMaxTokens int = 8091
param managedIdentityId string
param openAiChatModel string
param moveQueueName string

param processResultsContainer string
param appInsightsName string
param aiIndexName string

var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

var sbConnKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.SERVICEBUS_CONNECTION}/)'
var aiSearchKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY}/)'
var apimSubscriptionKeyKvReference ='@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.APIM_SUBSCRIPTION_KEY}/)' 

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' existing = {
  name: funcAppPlan
}

resource funcStorageAcct 'Microsoft.Storage/storageAccounts@2021-04-01'existing = {
  name: functionStorageAcctName
}
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAcct.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageAcct.listKeys().keys[0].value}'

resource aiSearchIndexFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: aiSearchIndexFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    keyVaultReferenceIdentity: managedIdentityId
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: false
      appSettings: [

        {
          name: configKeys.STORAGE_ACCOUNT_NAME
          value: formStorageAcctName
        }
        {
          name: configKeys.SERVICEBUS_CONNECTION
          value: sbConnKvReference
        }
        {
          name: configKeys.STORAGE_PROCESS_RESULTS_CONTAINER_NAME
          value: processResultsContainer
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
          name: configKeys.SERVICEBUS_NAMESPACE_NAME
          value: serviceBusNs
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
          name: configKeys.AZURE_AISEARCH_ENDPOINT
          value: aiSearchEndpoint
        }
        {
          name: configKeys.AZURE_AISEARCH_ADMIN_KEY
          value: aiSearchKvReference  
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
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: configKeys.AZURE_AISEARCH_INDEX_NAME
          value: aiIndexName
        }
        {
          name: configKeys.APIM_SUBSCRIPTION_KEY
          value: apimSubscriptionKeyKvReference
        }
      ]
    }
  }
}

output systemAssignedIdentity string = aiSearchIndexFunction.identity.principalId
