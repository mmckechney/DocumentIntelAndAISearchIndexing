param funcAppPlan string
param location string = resourceGroup().location
param askQuestionsFunctionName string
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param openAiEmbeddingModel string
param aiSearchEndpoint string
param openAiEndpoint string
param azureOpenAiEmbeddingMaxTokens int = 8091
param managedIdentityId string
param openAiChatModel string
param appInsightsName string
param cosmosDbName string
param cosmosContainerName string

var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

var cosmosKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.COSMOS_CONNECTION}/)'
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

resource askQuestions 'Microsoft.Web/sites@2021-01-01' = {
  name: askQuestionsFunctionName
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
          name:configKeys.COSMOS_CONNECTION
          value: cosmosKvReference
        }
        {
          name : configKeys.COSMOS_DB_NAME 
          value: cosmosDbName
        }
        {
          name : configKeys.COSMOS_CONTAINER_NAME 
          value: cosmosContainerName
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
          name: configKeys.APIM_SUBSCRIPTION_KEY
          value: apimSubscriptionKeyKvReference
        }
      ]
    }
  }
}

output systemAssignedIdentity string = askQuestions.identity.principalId
