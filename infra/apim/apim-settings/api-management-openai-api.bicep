@description('Name of the API.')
param name string
@description('Name of the API Management associated with the API.')
param apiManagementName string
@description('Display name of the API.')
param displayName string
@description('Relative URL for the API and all of its resource paths associated with the API Management resource.')
param path string
@description('Format for the OpenAPI specification.')
@allowed([
  'openapi'
  'openapi+json'
  'openapi+json-link'
  'openapi-link'
])
param format string
@description('Value for the OpenAPI specification.')
param value string
param loadBalancerName string

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementName
}

resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apiManagement
  name: name
  properties: {
    displayName: displayName
    path: path
    format: format
    value: value
    subscriptionRequired: true
  }
}

resource openaiApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' =  {
  name: 'policy'
  parent: api
  properties: {
    value: replace(loadTextContent('load-balancer-policy.xml'),'{{load-balancer-name}}', loadBalancerName)
    format: 'rawxml'
  }
  
}


@description('ID for the deployed API Management API resource.')
output id string = api.id
@description('Name for the deployed API Management API resource.')
output name string = api.name
