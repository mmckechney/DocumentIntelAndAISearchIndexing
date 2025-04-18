@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
    name: name
    location: location
    tags: tags
}

@description('ID for the deployed Managed Identity resource.')
output id string = identity.id
@description('Name for the deployed Managed Identity resource.')
output name string = identity.name
@description('Principal ID for the deployed Managed Identity resource.')
output principalId object = { id:identity.properties.principalId, name:'${identity.name}-UserAssignedIdentity'}
@description('Client ID for the deployed Managed Identity resource.')
output clientId string = identity.properties.clientId
