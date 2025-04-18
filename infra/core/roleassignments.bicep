param apimSystemAssignedIdentityPrincipalId object
param cosmosDbAccountName string
param currentUserObjectId object
param docIntelligencePrincipalIds array
param userAssignedManagedIdentityPrincipalId object
param containerRegistryName string


var principalIds = concat([currentUserObjectId], [userAssignedManagedIdentityPrincipalId], [apimSystemAssignedIdentityPrincipalId], docIntelligencePrincipalIds)

var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
var roles = loadJsonContent('../constants/roles.json')

module keyRoleAssignments 'roleassignments-general.bicep' = [for id in principalIds: {
  name: 'role-general-${id.name}'
  params: {
    cosmosDbAccountName: cosmosDbAccountName
    principalIds: id
  }
}]

module acrRoleAssignments 'roleassignments-acrpull.bicep' = [for id in principalIds: {
  name: 'role-acrpull-${id.name}'
  params: {
    containerRegistryName: containerRegistryName
    principalIds: [id]
  }
}]

//Document Intelligence Accounts -- these ALWAYS require RBAC access to the blob storage account
resource docIntelligenceBlobDataReaderAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in docIntelligencePrincipalIds: {
  name: guid(id.id, roles.storageBlobDataReader.roleId, deploymentEntropy)
  properties: {
    description: '${id.name} Blob Data Reader - ${id.id}'
    principalId: id.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles.storageBlobDataReader.roleId)
  }
  scope: resourceGroup()
}]

resource apimCogServicesUserAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(!empty(id)) {
  name: guid(id.id, roles.cognitiveServicesUser.roleId, deploymentEntropy)
  properties: {
    description: '${id.name} Cognitive Services User - ${id}'
    principalId: id.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles.cognitiveServicesUser.roleId)
  }
  scope: resourceGroup()
}]

output principalIds array = principalIds


