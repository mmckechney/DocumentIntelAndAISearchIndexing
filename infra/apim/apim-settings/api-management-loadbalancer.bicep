import * as customTypes from '../../constants/customTypes.bicep'

@description('Name of the Loadbalancer config.')
param name string
@description('Name of the API Management associated with the Backend.')
param apiManagementName string
@description('URL of the Backend.')
param openAiDeployments customTypes.openAiDeploymentInfo[]

resource apiManagement 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementName
}

var services = [for deployment in openAiDeployments: {
  id: deployment.id
  priority: deployment.?priority
}]

resource loadbalancer 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: apiManagement
  name: name
  properties: {
    type: 'Pool'
    url: 'https://www.backend-pool.com'
    protocol: 'http'
    pool: {
      services: services
    }
  }
}
  



@description('ID for the deployed API Management Backend resource.')
output id string = loadbalancer.id
@description('Name for the deployed API Management Backend resource.')
output name string = loadbalancer.name
