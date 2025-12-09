param location string = resourceGroup().location

param docIntelligenceName string
param docIntelligenceInstanceCount int = 1
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

output docIntelligenceAccountName string = docIntelligenceAccount[0].properties.endpoint

//get the id of each docIntelligence account created
output docIntelligenceAccountIds array = [for (i, formIndex) in range(0,docIntelligenceInstanceCount): docIntelligenceAccount[i].id]
output docIntelligencePrincipalIds array = [for i in range(0,docIntelligenceInstanceCount): docIntelligenceAccount[i].identity.principalId]
output docIntellEndpoint string = docIntelligenceAccount[0].properties.endpoint
output docIntellEndpoints array = [for i in range(0, docIntelligenceInstanceCount): docIntelligenceAccount[i].properties.endpoint]



