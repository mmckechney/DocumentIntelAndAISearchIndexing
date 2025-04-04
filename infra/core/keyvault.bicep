
param keyVaultName string
param location string = resourceGroup().location
param useManagedIdentity bool 
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
    enablePurgeProtection: true
    enableRbacAuthorization: useManagedIdentity
    accessPolicies: [
      
    ]

  }
}




output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id


