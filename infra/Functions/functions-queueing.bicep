param funcAppPlan string
param location string = resourceGroup().location
param functionSubnetId string
param functionStorageAcctName string
param serviceBusNs string
param formStorageAcctName string
param queueFunctionName string
param docQueueName string
param managedIdentityId string
param keyVaultUri string
param documentStorageContainer string
param appInsightsName string
param cosmosDbName string
param cosmosContainerName string


var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')
var cosmosKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.COSMOS_CONNECTION}/)'

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

resource queueingFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: queueFunctionName
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
          name: configKeys.STORAGE_SOURCE_CONTAINER_NAME
          value: documentStorageContainer
        }
        {
          name: configKeys.STORAGE_ACCOUNT_NAME
          value: formStorageAcctName
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

output systemAssignedIdentity string = queueingFunction.identity.principalId
