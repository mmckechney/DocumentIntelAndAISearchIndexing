param aiSearchName string
param keyVaultName string
param location string = resourceGroup().location



resource aiSearchInstance 'Microsoft.Search/searchServices@2022-09-01' = {
  name: aiSearchName
  location: location
  sku: {
    name: 'basic'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource adminKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'AZURE-AISEARCH-ADMIN-KEY'
  properties: {
    value:  aiSearchInstance.listAdminKeys().primaryKey
  }
}

output aiSearchEndpoint string = 'https://${aiSearchName}.search.windows.net'
