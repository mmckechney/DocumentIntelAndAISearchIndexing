param name string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
@secure()
param logAnalyticsSharedKey string
param infrastructureSubnetId string

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// Enable the Aspire Dashboard for the Container Apps Environment
resource aspireDashboard 'Microsoft.App/managedEnvironments/dotNetComponents@2024-10-02-preview' = {
  name: 'aspire-dashboard'
  parent: managedEnvironment
  properties: {
    componentType: 'AspireDashboard'
  }
}

output id string = managedEnvironment.id
output name string = managedEnvironment.name
