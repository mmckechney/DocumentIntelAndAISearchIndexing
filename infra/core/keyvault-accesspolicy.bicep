param apimSystemIdentityId object
param currentUserObjectId object
param userAssignedManagedIdentity object

param keyVaultName string

var ids = concat( [currentUserObjectId, apimSystemIdentityId, userAssignedManagedIdentity]) 
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// Create individual access policy entries for each principal ID
resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [for principalId in ids: {
      objectId: principalId.id
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
      tenantId: subscription().tenantId
    }]
  }
}
