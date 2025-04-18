param aiSearchName string
param keyVaultName string
param location string = resourceGroup().location

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')
resource aiSearchInstance 'Microsoft.Search/searchServices@2023-11-01' = {
  location: location
  name: aiSearchName
  sku: {
    name: 'basic'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource adminKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: keyVaultKeys.AZURE_AISEARCH_ADMIN_KEY
  parent: keyVault
  properties: {
    value: aiSearchInstance.listAdminKeys().primaryKey
  }
}

output aiSearchEndpoint string = 'https://${aiSearchName}.search.windows.net'
