@description('Name of the Backend.')
param name string
@description('Name of the API Management associated with the Backend.')
param apiManagementName string
@description('URL of the Backend.')
param url string

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementName
  resource backend 'backends@2023-05-01-preview' = {
    name: name
    properties: {
      protocol: 'http'
      url: url
      circuitBreaker: {
        rules: [
          {
            failureCondition: {
              count: 1
              errorReasons: [
                'Server errors'
              ]
              interval: 'PT10S'
              statusCodeRanges: [
                {
                  min: 400
                  max: 599
                }
              ]
            }
            name: '${name}-BreakerRule'
            tripDuration: 'PT10S'
          }
        ]
      }
  
    }
    
  }
}

@description('ID for the deployed API Management Backend resource.')
output id string = apiManagement::backend.id
@description('Name for the deployed API Management Backend resource.')
output name string = apiManagement::backend.name
