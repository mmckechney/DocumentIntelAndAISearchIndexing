param funcAppPlan string
param location string = resourceGroup().location
param processFunctionName string
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param docQueueName string
param customFieldQueueName string
param serviceBusNs string
param formStorageAcctName string
param managedIdentityId string
param documentStorageContainer string
param processResultsContainer string
param appInsightsName string


var configKeys = loadJsonContent('../constants/configKeys.json')
var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

var sbConnKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.SERVICEBUS_CONNECTION}/)'
var frEndpointKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT}/)'
var frKeyKvReference = '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY}/)'




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

resource processFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: processFunctionName
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
          name: configKeys.STORAGE_SOURCE_CONTAINER_NAME
          value: documentStorageContainer
        }
        {
          name: configKeys.STORAGE_PROCESS_RESULTS_CONTAINER_NAME
          value: processResultsContainer
        }
        {
          name: configKeys.STORAGE_ACCOUNT_NAME
          value: formStorageAcctName
        }
        {
          name:  configKeys.DOCUMENT_INTELLIGENCE_MODEL_NAME
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
          name: configKeys.SERVICEBUS_CONNECTION
          value: sbConnKvReference
        }
        {
          name: configKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME
          value: customFieldQueueName
        }
        {
          name: configKeys.SERVICEBUS_DOC_QUEUE_NAME
          value: docQueueName 
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
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
}

output systemAssignedIdentity string =  processFunction.identity.principalId
