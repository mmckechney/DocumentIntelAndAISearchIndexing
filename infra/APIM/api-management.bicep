import * as customTypes from '../constants/customTypes.bicep'


@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}
@description('ID for the Managed Identity associated with the API Management resource.')
param apiManagementIdentityId string
@description('ID for the subnet to deploy the API Management resource.')
param subnetId string
@description('Email address of the owner for the API Management resource.')
@minLength(1)
param publisherEmail string
@description('Name of the owner for the API Management resource.')
@minLength(1)
param publisherName string
@description('API Management SKU. Defaults to Developer, capacity 1.')
param sku customTypes.apimSkuInfo = {
  name: 'Developer'
  capacity: 1
}
param openAIDeployments customTypes.openAiDeploymentInfo[] 

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: sku
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${apiManagementIdentityId}': {}
    }
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External' 
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
  }
}



module openAIApiBackend 'apim-settings/api-management-backend.bicep' = [for (item, index) in openAIDeployments: { 
  name: '${apiManagement.name}-backend-openai-${item.name}'
  params: {
    name: 'OPENAI${toUpper(item.name)}'
    apiManagementName: apiManagement.name
    url: '${item.host}openai'
  }
}
]



@description('ID for the deployed API Management resource.')
output id string = apiManagement.id
@description('Name for the deployed API Management resource.')
output name string = apiManagement.name
@description('Gateway URL for the deployed API Management resource.')
output gatewayUrl string = apiManagement.properties.gatewayUrl
output identity string = apiManagement.identity.principalId

output openAIApiBackends customTypes.openApiApimBackends[] = [for (item, index) in openAIDeployments: {
  name: openAIApiBackend[index].name
  id: openAIApiBackend[index].outputs.id
  priority: item.?priority
}]
