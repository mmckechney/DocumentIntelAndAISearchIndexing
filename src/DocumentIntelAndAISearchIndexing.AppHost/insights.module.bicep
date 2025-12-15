@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

param applicationType string = 'web'

param kind string = 'web'

resource law_insights 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: take('lawinsights-${uniqueString(resourceGroup().id)}', 63)
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
  tags: {
    'aspire-resource-name': 'law_insights'
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: take('insights-${uniqueString(resourceGroup().id)}', 260)
  kind: kind
  location: location
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: law_insights.id
  }
  tags: {
    'aspire-resource-name': 'insights'
  }
}

output appInsightsConnectionString string = insights.properties.ConnectionString

output name string = insights.name