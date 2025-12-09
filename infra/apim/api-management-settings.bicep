
import * as customTypes from '../constants/customTypes.bicep'


param apiManagementName string
param appInsightsName string
param openApiApimBackends customTypes.openApiApimBackends[]

var loadBalancerName = 'openai-loadbalancer'

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing= {
  name: apiManagementName
}

// https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management
// GitHub location for API specs: https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference
module openAIApi 'apim-settings/api-management-openai-api.bicep' = {
name: '${apiManagement.name}-api-openai'
  params: {
    name: 'openai'
    loadBalancerName: apimLoadBalancing.outputs.name
    apiManagementName: apiManagement.name
    path: '/openai'
    format: 'openapi-link'
    displayName: 'OpenAI'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/refs/heads/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-10-21/inference.json'
  }
}




module apimLogger 'apim-settings/api-management-logger.bicep' = {
  name: '${apiManagement.name}-logger'
  params: {
    apiManagementName: apiManagement.name
    appInsightsName: appInsightsName
  }
}

module apimLoadBalancing 'apim-settings/api-management-loadbalancer.bicep' = {
  name: '${apiManagement.name}-loadbalancer'
  params: {
    apiManagementName: apiManagement.name
    openApiApimBackends: openApiApimBackends
    name: loadBalancerName
  }
}


