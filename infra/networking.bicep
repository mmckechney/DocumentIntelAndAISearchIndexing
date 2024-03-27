param location string = resourceGroup().location
param nsg string
param vnet string
param subnet string
param funcsubnet string
param myPublicIp string


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsg
  location: location
}

resource networkSecurityGroupRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'LocalIP'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: myPublicIp
    destinationAddressPrefix: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    priority: 500
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
  }
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
          addressPrefix: '10.10.1.0/24'
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Web'
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
            }
            {
              service: 'Microsoft.Web'
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



output subnetIds array = [
  virtualNetwork.properties.subnets[0].id
  virtualNetwork.properties.subnets[1].id 

]

output functionSubnetId string= virtualNetwork.properties.subnets[0].id

