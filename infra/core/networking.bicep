param location string = resourceGroup().location
param nsg string
param vnet string
param subnet string
param funcsubnet string
param apimsubnet string


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
        name: funcsubnet
        properties: {
           addressPrefix: '10.10.4.0/23'
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
        name: apimsubnet
        properties: {
          addressPrefix: '10.10.2.0/24'
           delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.EventHub'
              locations: ['*']
            }
            {
              service: 'Microsoft.KeyVault'
              locations: ['*']
            }
            {
              service: 'Microsoft.ServiceBus'
              locations: ['*']
            }
            {
              service: 'Microsoft.Sql'
              locations: ['*']
            }
            {
              service: 'Microsoft.Storage'
              locations: ['*']
            }
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: ['*']
            }
          ]
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
  virtualNetwork.properties.subnets[2].id 

]
output vnetName string = virtualNetwork.name
output functionSubnetName string= virtualNetwork.properties.subnets[0].name
output functionSubnetId string= virtualNetwork.properties.subnets[0].id
output apimSubnetId string= virtualNetwork.properties.subnets[1].id
