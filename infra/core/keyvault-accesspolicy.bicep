param keyVaultName string
param functionAppPrincipalIds array
param currentUserObjectId string

var ids = concat(functionAppPrincipalIds, [currentUserObjectId]) 
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// Create individual access policy entries for each principal ID
resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [for principalId in ids: {
      tenantId: subscription().tenantId
      objectId: principalId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
    }]
  }
}
