param completedContainer string
param documentStorageContainer string
param formStorageAcct string
param funcStorageAcct string
param keyVaultName string
param location string = resourceGroup().location
param myPublicIp string
param processResultsContainer string
param subnetIds array

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource formStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  kind: 'StorageV2'
  location: location
  name: formStorageAcct
  properties: {
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: !empty(myPublicIp) ? [
        {
          action: 'Allow'
          value: myPublicIp
        }
      ] : []
      virtualNetworkRules:[for subnetId in subnetIds: {
        action: 'Allow'
        id: subnetId
      }]
    }
  }
  sku: {
    name: 'Standard_LRS'
  }
}

resource formBlobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: formStorageAccount
}

resource formIncomingStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: documentStorageContainer
  parent: formBlobService
}

resource formProcessedStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: processResultsContainer
  parent: formBlobService
}

resource formOutputstorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: completedContainer
  parent: formBlobService
}

resource funcStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  kind: 'StorageV2'
  location: location
  name: funcStorageAcct
  sku: {
    name: 'Standard_LRS'
  }
}

resource storageKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: keyVaultKeys.STORAGE_KEY
  parent: keyVault
  properties: {
    value: formStorageAccount.listKeys().keys[0].value
  }
}

resource storageConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: keyVaultKeys.STORAGE_CONNECTION
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${formStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${formStorageAccount.listKeys().keys[0].value}'
  }
}

output storageAccountId string = formStorageAccount.id
