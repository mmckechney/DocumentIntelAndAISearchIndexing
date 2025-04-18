param location string = resourceGroup().location
param containerRegistryName string
param sku string = 'Basic'


resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true // Keep enabled for initial deployment and ACR image builds
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}


output loginServer string = containerRegistry.properties.loginServer
output name string = containerRegistry.name
