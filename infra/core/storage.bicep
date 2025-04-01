
param location string = resourceGroup().location
param formStorageAcct string
param funcStorageAcct string
param myPublicIp string
param subnetIds array

param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param keyVaultName string 

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}


var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource formStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: formStorageAcct
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: !empty(myPublicIp) ? [
        {
          value: myPublicIp
          action: 'Allow'
        }
      ] : []
      virtualNetworkRules:[for subnetId in subnetIds: {
        
          id: subnetId
          action: 'Allow'
        }
     ]
      
    }

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
  name: funcStorageAcct
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: keyVaultKeys.STORAGE_KEY
  properties: {
    value: formStorageAccount.listKeys().keys[0].value
  }
}


output storageAccountId string = formStorageAccount.id
