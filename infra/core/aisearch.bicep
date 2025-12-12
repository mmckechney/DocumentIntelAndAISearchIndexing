param aiSearchName string
param location string = resourceGroup().location

resource aiSearchInstance 'Microsoft.Search/searchServices@2023-11-01' = {
  name: aiSearchName
  location: location
  sku: {
    name: 'basic'
  }
  properties:{
     disableLocalAuth: true
  }
}
output aiSearchEndpoint string = 'https://${aiSearchName}.search.windows.net'
