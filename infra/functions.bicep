param funcAppPlan string
param location string = resourceGroup().location
param processFunctionName string
param aiSearchIndexFunctionName string
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param processedQueueName string
param serviceBusNs string
param formStorageAcctName string
param moveFunctionName string
param queueFunctionName string
param formQueueName string
param toIndexQueueName string
param azureOpenAiAccountName string
param azureOpenAiResourceGroupName string
param openAiEmbeddingModel string
param openAiEmbeddingDeployment string
param aiSearchEndpoint string
param azureOpenAiEmbeddingMaxTokens int

param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param appInsightsName string
param includeGeneralIndex bool = true

var sbConnKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/SERVICE-BUS-CONNECTION/)'
var frEndpointKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/DOCUMENT-INTELLIGENCE-ENDPOINT/)'
var frKeyKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/DOCUMENT-INTELLIGENCE-KEY/)'
var aiSearchKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/AZURE-AISEARCH-ADMIN-KEY/)'
var openAIKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/AZURE-OPENAI-KEY/)'

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2021-04-30' existing = {
  name: azureOpenAiAccountName
  scope: resourceGroup(azureOpenAiResourceGroupName)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}


resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: funcAppPlan
  location: location
  sku: {
    name: 'EP1'
    capacity: 4 
  }
  properties: {
    reserved: false 
  }
}

resource funcStorageAcct 'Microsoft.Storage/storageAccounts@2021-04-01'existing = {
  name: functionStorageAcctName
}
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAcct.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageAcct.listKeys().keys[0].value}'

resource processFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: processFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: true
      appSettings: [
        {
          name: 'DOCUMENT_SOURCE_CONTAINER_NAME'
          value: documentStorageContainer
        }
        {
          name: 'DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME'
          value: processResultsContainer
        }
        {
          name: 'DOCUMENT_COMPLETED_CONTAINER_NAME'
          value: completedContainer
        }
        {
          name: 'DOCUMENT_STORAGE_ACCOUNT_NAME'
          value: formStorageAcctName
        }
        {
          name: 'DOCUMENT_INTELLIGENCE_MODEL_NAME'
          value: 'prebuilt-read'
        }
        {
          name: 'DOCUMENT_INTELLIGENCE_ENDPOINT'
          value: frEndpointKvReference
        }
        {
          name: 'DOCUMENT_INTELLIGENCE_KEY'
          value: frKeyKvReference
        }
        {
          name: 'SERVICE_BUS_CONNECTION'
          value: sbConnKvReference
        }
        {
          name: 'SERVICE_BUS_PROCESSED_QUEUE_NAME'
          value: processedQueueName
        }
        {
          name: 'SERVICE_BUS_TOINDEX_QUEUE_NAME'
          value: toIndexQueueName
        }
        {
          name: 'SERVICE_BUS_NAMESPACE_NAME'
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
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
}

resource aiSearchIndexFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: aiSearchIndexFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: true
      appSettings: [
        {
          name: 'DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME'
          value: processResultsContainer
        }
        {
          name: 'DOCUMENT_STORAGE_ACCOUNT_NAME'
          value: formStorageAcctName
        }
        {
          name: 'SERVICE_BUS_CONNECTION'
          value: sbConnKvReference
        }
        {
          name: 'SERVICE_BUS_TOINDEX_QUEUE_NAME'
          value: toIndexQueueName
        }
        {
          name: 'SERVICE_BUS_NAMESPACE_NAME'
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
          name: 'AZURE_AISEARCH_ENDPOINT'
          value: aiSearchEndpoint
        }
        {
          name: 'AZURE_AISEARCH_ADMIN_KEY'
          value: aiSearchKvReference  
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAiAccount.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: openAIKvReference
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_MODEL'
          value: openAiEmbeddingModel
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_DEPLOYMENT'
          value: openAiEmbeddingDeployment  
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_MAXTOKENS'
          value: string(azureOpenAiEmbeddingMaxTokens)
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_AISEARCH_INCLUDE_GENERAL_INDEX'
          value: includeGeneralIndex ? 'true' : 'false'
        }
      ]
    }
  }
}

resource moveFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: moveFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: true
      appSettings: [
        {
          name: 'DOCUMENT_SOURCE_CONTAINER_NAME'
          value: documentStorageContainer
        }
        {
          name: 'DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME'
          value: processResultsContainer
        }
        {
          name: 'DOCUMENT_STORAGE_ACCOUNT_NAME'
          value: formStorageAcctName
        }
        {
          name: 'SERVICE_BUS_CONNECTION'
          value: sbConnKvReference
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
          name: 'SERVICE_BUS_PROCESSED_QUEUE_NAME'
          value: processedQueueName
        }
        {
          name: 'SERVICE_BUS_MOVE_QUEUE_NAME'
          value: moveFunctionName
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
      ]
    }
  }
}

resource queueFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: queueFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: true
      appSettings: [
        {
          name: 'DOCUMENT_SOURCE_CONTAINER_NAME'
          value: documentStorageContainer
        }
        {
          name: 'DOCUMENT_STORAGE_ACCOUNT_NAME'
          value: formStorageAcctName
        }
        {
          name: 'SERVICE_BUS_NAMESPACE_NAME'
          value: serviceBusNs
        }
        {
          name: 'SERVICE_BUS_QUEUE_NAME'
          value: formQueueName
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
      ]
    }
  }
}


output queueFunctionId string = queueFunction.identity.principalId
output moveFunctionId string = moveFunction.identity.principalId
output processFunctionId string = processFunction.identity.principalId
output aiSearchIndexFunctionId string = aiSearchIndexFunction.identity.principalId
