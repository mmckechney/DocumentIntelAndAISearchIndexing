@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

resource aisearch 'Microsoft.Search/searchServices@2023-11-01' = {
  name: take('aisearch-${uniqueString(resourceGroup().id)}', 60)
  location: location
  properties: {
    hostingMode: 'default'
    disableLocalAuth: true
    partitionCount: 1
    replicaCount: 1
  }
  sku: {
    name: 'basic'
  }
  tags: {
    'aspire-resource-name': 'aisearch'
  }
}

output connectionString string = 'Endpoint=https://${aisearch.name}.search.windows.net'

output name string = aisearch.name