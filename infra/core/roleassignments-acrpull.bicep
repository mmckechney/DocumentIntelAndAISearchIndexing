param principalIds array
param containerRegistryName string


var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
var roles = loadJsonContent('../constants/roles.json')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// Azure Container Registry pull role assignment for function apps
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(!empty(id)) {
  name: guid(id.id, roles.acrPull.roleId, containerRegistry.id, deploymentEntropy)
  properties: {
    description: '${id.name} ACR Pull - ${id.id}'
    principalId: id.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles.acrPull.roleId)
  }
  scope: containerRegistry
}]



