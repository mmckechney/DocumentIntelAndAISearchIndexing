param keyVaultName string
param location string = resourceGroup().location
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  location: location
  name: keyVaultName
  properties: {
    accessPolicies: []
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri


