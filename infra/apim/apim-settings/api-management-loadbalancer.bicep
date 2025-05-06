import * as customTypes from '../../constants/customTypes.bicep'

@description('Name of the Loadbalancer config.')
param name string
@description('Name of the API Management associated with the Backend.')
param apiManagementName string
@description('URL of the Backend.')
param openApiApimBackends customTypes.openApiApimBackends[]

resource apiManagement 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementName
}

var services = [for deployment in openApiApimBackends: {
  id: deployment.id
  priority: deployment.?priority
}]

resource loadbalancer 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: apiManagement
  name: name
  properties: {
    type: 'Pool'
    pool: {
      services: services
    }
  }
}
  



@description('ID for the deployed API Management Backend resource.')
output id string = loadbalancer.id
@description('Name for the deployed API Management Backend resource.')
output name string = loadbalancer.name
