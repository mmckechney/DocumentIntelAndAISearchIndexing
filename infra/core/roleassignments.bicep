param docIntelligencePrincipalIds array
param functionPrincipalIds array
param userAssignedManagedIdentityPrincipalId string = ''
param currentUserObjectId string = ''
param apimSystemAssignedIdentityPrincipalId string = ''
param useManagedIdentity bool 

// Use ternary operators to build the principalIds array conditionally
var withCurrentUser = !empty(currentUserObjectId) ? concat(functionPrincipalIds, [currentUserObjectId]) : functionPrincipalIds

var principalIds = useManagedIdentity && !empty(userAssignedManagedIdentityPrincipalId) 
  ? concat(withCurrentUser, [userAssignedManagedIdentityPrincipalId]) 
  : withCurrentUser

var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
var roles = loadJsonContent('../constants/roles.json')

resource blobDataContrib 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataContributor
}

resource blobDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataOwner
}

resource serviceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.serviceBusDataOwner
}

resource keyVaultSecretUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.keyVaultSecretsUser
}

resource blobDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataReader
}

resource cognitiveServicesUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cognitiveServicesUser
}

//Document Intelligence Accounts -- these ALWAYS require RBAC access to the blob storage account
resource docIntelligenceBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in docIntelligencePrincipalIds: {
  name: guid(id, blobDataReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataReader.id
    principalId: id
  }
}]


resource apimCogServicesUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (useManagedIdentity && !empty(userAssignedManagedIdentityPrincipalId)) {
  name: guid(userAssignedManagedIdentityPrincipalId, cognitiveServicesUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesUser.id
    principalId: userAssignedManagedIdentityPrincipalId
  }
}

resource apimSysAssignedCogServicesUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (useManagedIdentity &&!empty(apimSystemAssignedIdentityPrincipalId)) {
  name: guid(apimSystemAssignedIdentityPrincipalId, cognitiveServicesUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesUser.id
    principalId: apimSystemAssignedIdentityPrincipalId
  }
}


//Function identities and current user - only deploy these if useManagedIdentity is true
resource functionManagedIdentityBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(useManagedIdentity) {
  name: guid(id, blobDataContrib.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataContrib.id
    principalId: id
  }
}]

resource functionManagedIdentityBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(useManagedIdentity) {
  name: guid(id, blobDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataOwner.id
    principalId: id
  }
}]

resource functionManagedIdentityServiceBusDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(useManagedIdentity) {
  name: guid(id, serviceBusDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwner.id
    principalId: id
  }
}]

resource functionManagedIdentityKeyVaultSecretUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: if(useManagedIdentity) {
  name: guid(id, keyVaultSecretUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretUser.id
    principalId: id
  }
}]
output principalIds array = principalIds


