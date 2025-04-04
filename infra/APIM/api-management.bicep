@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}
@description('ID for the Managed Identity associated with the API Management resource.')
param apiManagementIdentityId string
@description('Whether to use Managed Identity for authentication')
param useManagedIdentity bool 

@description('ID for the subnet to deploy the API Management resource.')
param subnetId string

type skuInfo = {
  name: 'Developer' | 'Standard' | 'Premium' | 'Basic' | 'Consumption' | 'Isolated'
  capacity: int
}

@description('Email address of the owner for the API Management resource.')
@minLength(1)
param publisherEmail string
@description('Name of the owner for the API Management resource.')
@minLength(1)
param publisherName string
@description('API Management SKU. Defaults to Developer, capacity 1.')
param sku skuInfo = {
  name: 'Developer'
  capacity: 1
}

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: sku
  identity: {
    type: useManagedIdentity ? 'SystemAssigned, UserAssigned' : 'SystemAssigned'
    userAssignedIdentities: useManagedIdentity && !empty(apiManagementIdentityId) ? {
      '${apiManagementIdentityId}': {}
    } : null
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

@description('ID for the deployed API Management resource.')
output id string = apiManagement.id
@description('Name for the deployed API Management resource.')
output name string = apiManagement.name
@description('Gateway URL for the deployed API Management resource.')
output gatewayUrl string = apiManagement.properties.gatewayUrl
output systemIdentity string = apiManagement.identity.principalId
output userAssignedIdentity string = apiManagementIdentityId
