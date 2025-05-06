import * as customTypes from '../constants/customTypes.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}
param managedIdentityId string
param openAiConfig customTypes.openAIConfig
param completionModel string
param embeddingModel string


@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Properties to store in a Key Vault.')
param keyVaultConfig customTypes.keyVaultSecretsInfo = {
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

resource completionDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: cognitiveServices
  name: completionModel
  properties: {
    model: {
      format: 'OpenAI'
      name: completionModel
  }
  }
  sku:  {
    name: openAiConfig.completion.sku
    capacity: openAiConfig.completion.capacity
  }
}


resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: cognitiveServices
  name: embeddingModel
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModel
    }
  }
  sku:  {
    name: 'Standard'
    capacity: openAiConfig.embedding.capacity
  }
  dependsOn:[
      completionDeployment
 ]
}


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


output openAiInfo customTypes.openAiDeploymentInfo = {
  name: cognitiveServices.name
  id: cognitiveServices.id
  host: cognitiveServices.properties.endpoint
  endpoint: cognitiveServices.properties.endpoint
}
