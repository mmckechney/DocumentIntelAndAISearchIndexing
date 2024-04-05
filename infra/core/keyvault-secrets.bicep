param keyvault string
param docIntelKeyArray array


resource formRecognizerKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyvault}/DOCUMENT-INTELLIGENCE-KEY'
  properties: {
    value:    join(docIntelKeyArray,'|')
  }
}




