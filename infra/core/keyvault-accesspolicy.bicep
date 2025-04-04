param keyVaultName string
param functionAppPrincipalIds array
param currentUserObjectId string

var ids = concat(functionAppPrincipalIds, [currentUserObjectId]) 
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = [for principalId in ids: { 
  name: principalId
  parent: keyVault
  properties: {  
    accessPolicies: [  
      {  
        tenantId: subscription().tenantId  
        objectId: principalId  
        permissions: {  
          secrets: [  
            'get'
            'list'  
          ]  
        }  
      }  
    ]  
  }  
}]  
