@description('Names of the OpenAI backends.')
param openaiBackends array

@description('Name of the API Management associated with the Backend.')
param apiManagementName string


var services = [for backend in openaiBackends :{
    id: '/backends/${backend}'
    
  }]

output services array = services
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementName
  resource backend 'backends@2023-05-01-preview' = {
    name: 'aoai-lb-pool'
    properties: {
      type: 'pool'
      protocol: 'http'
      url: 'http://doesn-not-exist.com'
      pool: {
        services : [
          for backend in openaiBackends : {
            id: '/backends/${backend}'
          }
        ]
      }
  
    }
    
  }
}
