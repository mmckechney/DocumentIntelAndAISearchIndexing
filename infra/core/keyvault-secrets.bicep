param keyvault string
param docIntelKeyArray array

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource formRecognizerKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyvault}/${keyVaultKeys.DOCUMENT_INTELLIGENCE_KEY}'
  properties: {
    value:    join(docIntelKeyArray,'|')
  }
}




