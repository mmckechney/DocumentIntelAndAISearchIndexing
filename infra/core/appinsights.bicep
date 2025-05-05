param appInsightsName string
param logAnalyticsName string
param functionNames array
param location string = resourceGroup().location


var functionTags = reduce(functionNames, {}, (cur, functionName) => union(
  cur, 
  { 
    '${format('hidden-link:/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}', subscription().id, resourceGroup().name, functionName)}': 'Resource'
  }
))


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
  tags: functionTags
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
