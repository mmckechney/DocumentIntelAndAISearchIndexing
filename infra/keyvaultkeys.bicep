param keyvault string
param docIntelKeyArray array
param openAiAccountName string
param openAiResourceGroupName string


resource formRecognizerKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyvault}/DOCUMENT-INTELLIGENCE-KEY'
  properties: {
    value:    join(docIntelKeyArray,'|')
  }
}


resource openAiKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyvault}/AZURE-OPENAI-KEY'
  properties: {
    value:    openAiAccount.listKeys().key1
  }
}



resource openAiAccount 'Microsoft.CognitiveServices/accounts@2021-04-30' existing = {
  name: openAiAccountName
  scope: resourceGroup(openAiResourceGroupName)
}


