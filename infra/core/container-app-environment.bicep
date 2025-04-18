param location string = resourceGroup().location
param containerAppEnvName string
param logAnalyticsWorkspaceName string
param vnetName string
param subnetName string
param workloadProfileName string = 'Dedicated-D4'
param workloadProfileType string = 'D4'
//param userAssignedIdentityId string
param minReplicas int = 0
param maxReplicas int = 10

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${userAssignedIdentityId}': {}
  //   }
  // }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    vnetConfiguration: {
      infrastructureSubnetId: subnet.id
      internal: false
    }
    workloadProfiles:  [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      {
        maximumCount: maxReplicas
        minimumCount: minReplicas
        name: workloadProfileName
        workloadProfileType: workloadProfileType
      }
    ]
  }
}

output id string = containerAppEnvironment.id
output name string = containerAppEnvironment.name
