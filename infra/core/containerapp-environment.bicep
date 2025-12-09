param name string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
param logAnalyticsSharedKey string
param infrastructureSubnetId string

resource managedEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
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
  }
}

output id string = managedEnvironment.id
output name string = managedEnvironment.name
