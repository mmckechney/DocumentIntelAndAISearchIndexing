param funcAppPlan string
param location string = resourceGroup().location
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param processedQueueName string
param formStorageAcctName string
param moveFunctionName string
param managedIdentityId string

param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param appInsightsName string

var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

var sbConnKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.SERVICE_BUS_CONNECTION}/)'


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



resource moveFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: moveFunctionName
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
      remoteDebuggingEnabled: true
      appSettings: [
        {
          name: configKeys.DOCUMENT_SOURCE_CONTAINER_NAME
          value: documentStorageContainer
        }
        {
          name: configKeys.DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME
          value: processResultsContainer
        }
        {
          name: configKeys.DOCUMENT_COMPLETED_CONTAINER_NAME
          value: completedContainer
        }
        {
          name: configKeys.DOCUMENT_STORAGE_ACCOUNT_NAME
          value: formStorageAcctName
        }
        {
          name: configKeys.SERVICE_BUS_CONNECTION
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
          name: configKeys.SERVICE_BUS_PROCESSED_QUEUE_NAME
          value: processedQueueName
        }
        {
          name: configKeys.SERVICE_BUS_MOVE_QUEUE_NAME
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


output systemAssignedIdentity string =  moveFunction.identity.principalId
