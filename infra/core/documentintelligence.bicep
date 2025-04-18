param location string = resourceGroup().location

param docIntelligenceName string
param docIntelligenceInstanceCount int = 1
param keyVaultName string


resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource docIntelligenceAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = [for i in range(0,docIntelligenceInstanceCount): {
  name: '${docIntelligenceName}_${padLeft(i, 2,'0')}'
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
   publicNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
 
}]

resource formRecognizerEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: keyVaultKeys.DOCUMENT_INTELLIGENCE_ENDPOINT
  properties: {
    value: docIntelligenceAccount[0].properties.endpoint
  }
}

output docIntelligenceAccountName string = docIntelligenceAccount[0].properties.endpoint

//get the id of each docIntelligence account created
output docIntelligenceAccountIds array = [for (i, formIndex) in range(0,docIntelligenceInstanceCount): docIntelligenceAccount[i].id]
output docIntelligencePrincipalIds array = [for i in range(0,docIntelligenceInstanceCount): {id: docIntelligenceAccount[i].identity.principalId, name: '${docIntelligenceAccount[i].name}-SystemAssignedIdentity'}]
output docIntellKeyArray array = [for i in range(0,docIntelligenceInstanceCount):   docIntelligenceAccount[i].listKeys().key1]
output docIntellEndpoint string = docIntelligenceAccount[0].properties.endpoint



