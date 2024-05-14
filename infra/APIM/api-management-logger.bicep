param apiManagementName string
param appInsightsName string



resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementName
}
  resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
    name: appInsightsName
  }


  resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apiManagement
  name: 'apimlogger'
  properties:{
    resourceId: appInsights.id
    description: 'Application Insights for APIM'
    loggerType: 'applicationInsights'
    credentials:{
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}
