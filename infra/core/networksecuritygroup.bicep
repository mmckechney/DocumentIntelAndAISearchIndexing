param nsg string
param myPublicIp string
param location string = resourceGroup().location


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsg
  location: location
}

resource allowLocalPublicIPRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = if(myPublicIp != ''){
  name: 'AllowLocalIP'
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

resource internetToVnetInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'InternetToVnetInbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationPortRange: '443'
    priority: 505
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
  }
}

resource trafficManagertoVnetOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'trafficManagertoVnetOutbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'AzureTrafficManager'
    destinationAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationPortRange: '443'
    priority: 600
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
  }
}

resource apimManagementInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'ApimManagementInbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'ApiManagement'
    destinationAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationPortRange: '3443'
    priority: 510
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
  }
}
resource loadBalancerToVnetInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'LoadBalancerToVnetInbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
    destinationPortRange: '6390'
    priority: 520
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
  }
}

resource vnetToStorageOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'VnetToStorageOutbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Storage'
    sourcePortRange: '*'
    destinationPortRange: '443'
    priority: 530
    access: 'Allow'
    direction: 'Outbound'
    protocol: 'Tcp'
  }
}

resource vnetToSQLOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'VnetToSQLOutbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'SQL'
    sourcePortRange: '*'
    destinationPortRange: '1443'
    priority: 540
    access: 'Allow'
    direction: 'Outbound'
    protocol: 'Tcp'
  }
}

resource vnetToKeyVaultOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'VnetToKeyVaultOutbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureKeyVault'
    sourcePortRange: '*'
    destinationPortRange: '433'
    priority: 550
    access: 'Allow'
    direction: 'Outbound'
    protocol: 'Tcp'
  }
}

resource vnetToAzureMonitorOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = {
  name: 'VnetToAzureMonitorOutbound'
  parent: networkSecurityGroup
  properties: {
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureMonitor'
    sourcePortRange: '*'
    destinationPortRanges: [
      '443'
      '1886'
    ]
    priority: 560
    access: 'Allow'
    direction: 'Outbound'
    protocol: 'Tcp'
  }
}





