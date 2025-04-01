@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}
param managedIdentityId string

type roleAssignmentInfo = {
  roleDefinitionId: string
  principalId: string
}

type keyVaultSecretsInfo = {
  keyVaultName: string
  primaryKeySecretName: string
}

@description('List of model deployments.')
param deployments array = []
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Properties to store in a Key Vault.')
param keyVaultConfig keyVaultSecretsInfo = {
  keyVaultName: ''
  primaryKeySecretName: ''
}
// @description('Role assignments to create for the Azure OpenAI Service instance.')
// param roleAssignments roleAssignmentInfo[] = []

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: publicNetworkAccess
  }
  sku: {
    name: 'S0'
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  parent: cognitiveServices
  name: deployment.name
  properties: {
    model: deployment.?model ?? null
    raiPolicyName: deployment.?raiPolicyName ?? null
  }
  sku: deployment.?sku ?? {
    name: 'Standard'
    capacity: 20
  }
}]

resource keyVaultSecrets 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultConfig.keyVaultName
}

resource adminKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVaultSecrets
  name: keyVaultConfig.primaryKeySecretName
  properties: {
    value:  cognitiveServices.listKeys().key1
  }
}


@description('ID for the deployed Cognitive Services resource.')
output id string = cognitiveServices.id
@description('Name for the deployed Cognitive Services resource.')
output name string = cognitiveServices.name
@description('Endpoint for the deployed Cognitive Services resource.')
output endpoint string = cognitiveServices.properties.endpoint
@description('Host for the deployed Cognitive Services resource.')
output host string = split(cognitiveServices.properties.endpoint, '/')[2]
