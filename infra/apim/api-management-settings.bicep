
import * as customTypes from '../constants/customTypes.bicep'


param apiManagementName string
param keyvaultName string
param keyVaultUri string
param openAiApiName string
param appInsightsName string
param openAIDeployments customTypes.openAiDeploymentInfo[]
param openApiApimBackends customTypes.openApiApimBackends[]

param userAssignedIdentityId string

var loadBalancerName = 'openai-loadbalancer'

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing= {
  name: apiManagementName
}

module openAIApiKeyNamedValue 'apim-settings/api-management-key-vault-named-value.bicep' = [ for openAi in openAIDeployments: {
  name: 'NV-OPENAI-API-KEY-${toUpper(openAi.name)}'
  params: {
    name: 'OPENAI-API-KEY-${toUpper(openAi.name)}'
    displayName: 'OPENAI-API-KEY-${toUpper(openAi.name)}'
    apiManagementName: apiManagement.name
    apiManagementIdentityClientId: userAssignedIdentityId
        keyVaultSecretUri: '${keyVaultUri}secrets/OPENAI-API-KEY-${toUpper(openAi.name)}/'
  }
 
}]

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




module apiSubscription 'apim-settings/api-management-subscription.bicep' = {
  name: '${apiManagement.name}-subs-openai'
  params: {
    name: 'openai'
    apiManagementName: apiManagement.name
    displayName: 'OpenAI API Subscription'
    //scope: '/apis/${openAIApi.outputs.name}'
    scope: '/apis/${openAiApiName}'
    keyVaultName: keyvaultName
  }
  dependsOn:[
    openAIApi
  ]
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
  dependsOn: [
    openAIApiKeyNamedValue
  ]
}


