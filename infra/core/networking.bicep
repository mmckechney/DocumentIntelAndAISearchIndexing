param location string = resourceGroup().location
param nsg string
param vnet string
param subnet string
param appsubnet string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: nsg
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
       {
        name: appsubnet
        properties: {
           addressPrefix: '10.10.4.0/23'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Web'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.ServiceBus'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: ['*']
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
       }
      {
        name: subnet
        properties: {
          addressPrefix: '10.10.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Web'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.ServiceBus'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: ['*']
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
       }
    ]
  }
}



output storageSubnetIds array = [
  virtualNetwork.properties.subnets[0].id
  virtualNetwork.properties.subnets[1].id 

]
output vnetName string = virtualNetwork.name
output appSubNetName string= virtualNetwork.properties.subnets[0].name
output appSubNetId string= virtualNetwork.properties.subnets[0].id

