param appInsightsName string
param logAnalyticsName string
param location string = resourceGroup().location


resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output name string = appInsights.name
@secure()
output connectionString string = appInsights.properties.ConnectionString
output resourceId string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output logAnalyticsResourceId string = logAnalytics.id
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
@secure()
output logAnalyticsSharedKey string = listKeys(logAnalytics.id, '2020-08-01').primarySharedKey
