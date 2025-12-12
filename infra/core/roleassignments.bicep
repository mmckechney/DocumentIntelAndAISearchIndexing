param docIntelligencePrincipalIds array
param functionPrincipalIds array
param userAssignedManagedIdentityPrincipalId string
param currentUserObjectId string
param containerRegistryName string
param cosmosAccountName string
param cosmosAccountResourceGroup string


//Combine the function and current user (if supplied) and principal ids
var principalIds = !empty(currentUserObjectId) ? concat(functionPrincipalIds, [
  currentUserObjectId
  userAssignedManagedIdentityPrincipalId
]) : concat(functionPrincipalIds, [
  userAssignedManagedIdentityPrincipalId
])

var acrPrincipalIds = !empty(currentUserObjectId) ? concat(functionPrincipalIds, [
  currentUserObjectId
]) : functionPrincipalIds

var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
var roles = loadJsonContent('../constants/roles.json')

module cosmosDataPlane 'cosmos-dataplane-roleassignments.bicep' = {
  name: 'cosmos-dataplane-roleassignments'
  params: {
    principalIds: principalIds
    accountName: cosmosAccountName
    cosmosRg: cosmosAccountResourceGroup
    
  }
}

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

resource storageQueueDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageQueueDataContributor
}

resource storageTableDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageTableDataContributor
}

resource keyVaultSecretUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.keyVaultSecretsUser
}

resource blobDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataReader
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.acrPull
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource cognitiveServicesUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cognitiveServicesUser
}

resource cognitiveServicesContributor'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cognitiveServicesContributor
}

resource searchIndexDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchIndexDataContributor
}

resource searchIndexDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchIndexDataReader
}

resource cosmosDbAccountReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbAccountReader
}








resource cosmosDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbBuiltInDataContributor
}

resource cosmosDbOperator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbOperator
}



resource searchServiceContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchServiceContributor
}


//Document Intelligence Accounts 
resource docIntelligenceBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in docIntelligencePrincipalIds: {
  name: guid(id, blobDataReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataReader.id
    principalId: id
  }
}]


//Function identities and current user
resource functionManagedIdentityBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, blobDataContrib.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataContrib.id
    principalId: id
  }
}]

resource functionManagedIdentityBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' =  [for id in principalIds: {
  name: guid(id, blobDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataOwner.id
    principalId: id
  }
}]

resource functionManagedIdentityServiceBusDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, serviceBusDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwner.id
    principalId: id
  }
}]

resource functionManagedIdentityStorageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, storageQueueDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageQueueDataContributor.id
    principalId: id
  }
}]

resource functionManagedIdentityStorageTableDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, storageTableDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageTableDataContributor.id
    principalId: id
  }
}]

resource functionManagedIdentityKeyVaultSecretUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, keyVaultSecretUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretUser.id
    principalId: id
  }
}]

resource functionManagedIdentitySearchServiceContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchServiceContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchServiceContributor.id
    principalId: id
  }
}]

resource functionManagedIdentityCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cognitiveServicesUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesUser.id
    principalId: id
  }
}]

resource functionManagedIdentityCognitiveServicesContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cognitiveServicesContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesContributor.id
    principalId: id
  }
}]


resource functionManagedIdentitySearchIndexDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchIndexDataReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchIndexDataReader.id
    principalId: id
  }
}]

resource functionManagedIdentitySearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchIndexDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchIndexDataContributor.id
    principalId: id
  }
}]


resource functionManagedIdentityCosmosDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDataContributor.id
    principalId: id
  }
}]


resource functionManagedIdentityComsmosDbOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDbOperator.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDbOperator.id
    principalId: id
  }
}]

resource functionManagedIdentityComsmosDbAccountReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDbAccountReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDbAccountReader.id
    principalId: id
  }
}]

resource principalAcrPullAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in acrPrincipalIds: {
  name: guid(id, acrPullRole.id, containerRegistry.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: id
  }
}]
output principalIds array = principalIds


