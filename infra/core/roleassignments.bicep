param docIntelligencePrincipalIds array
param functionPrincipalIds array
param userAssignedManagedIdentityPrincipalId string
param currentUserObjectId string
param cosmosAccountName string
param cosmosAccountResourceGroup string


//Combine the function and current user (if supplied) and principal ids
var principalIds = !empty(currentUserObjectId) ? concat(functionPrincipalIds, [
  currentUserObjectId
  userAssignedManagedIdentityPrincipalId
]) : concat(functionPrincipalIds, [
  userAssignedManagedIdentityPrincipalId
])


var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3301'
var roles = loadJsonContent('../constants/roles.json')


module cosmosDataPlane 'cosmos-dataplane-roleassignments.bicep' = {
  name: 'cosmos-dataplane-roleassignments'
  params: {
    principalIds: principalIds
    accountName: cosmosAccountName
    cosmosRg: cosmosAccountResourceGroup
    
  }
}


//Blob Data Reader Role Assignments
resource blobDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataReader
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


//Blob Data Contributor Role Assignments
resource blobDataContrib 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataContributor
}

resource miBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, blobDataContrib.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataContrib.id
    principalId: id
    description: 'storageBlobDataContributor for ${id}'
  }
}]

//Blob Data Owner Role Assignments
resource blobDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageBlobDataOwner
}

resource miBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' =  [for id in principalIds: {
  name: guid(id, blobDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: blobDataOwner.id
    principalId: id
    description: 'storageBlobDataOwner for ${id}'
  }
}]

//Service Bus Data Owner Role Assignments
resource serviceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.serviceBusDataOwner
}
resource miServiceBusDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, serviceBusDataOwner.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwner.id
    principalId: id
    description: 'serviceBusDataOwner for ${id}'
  }
}]

//Storage Queue Data Contributor Role Assignments
resource storageQueueDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageQueueDataContributor
}

resource miStorageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, storageQueueDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageQueueDataContributor.id
    principalId: id
    description: 'storageQueueDataContributor for ${id}'
  }
}]


//Storage Table Data Contributor Role Assignments
resource storageTableDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.storageTableDataContributor
}

resource miStorageTableDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, storageTableDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageTableDataContributor.id
    principalId: id
    description: 'storageTableDataContributor for ${id}'
  }
}]

//Search Service Contributor Role Assignments
resource searchServiceContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchServiceContributor
}

resource miSearchServiceContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchServiceContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchServiceContributor.id
    principalId: id
    description: 'searchServiceContributor for ${id}'
  }
}]

//Cognitive Services Role Assignments
resource cognitiveServicesUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cognitiveServicesUser
}

resource miCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cognitiveServicesUser.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesUser.id
    principalId: id
    description: 'cognitiveServicesUser for ${id}'
  }
}]

//Cognitive Services Contributor Role Assignments
resource cognitiveServicesContributor'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cognitiveServicesContributor
}

resource miCognitiveServicesContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cognitiveServicesContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesContributor.id
    principalId: id
    description: 'cognitiveServicesContributor for ${id}'
  }
}]

//AI Search Data Reader Role Assignments
resource searchIndexDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchIndexDataReader
}

resource miSearchIndexDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchIndexDataReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchIndexDataReader.id
    principalId: id
    description: 'searchIndexDataReader for ${id}'
  }
}]

//AI Search Data Contributor Role Assignments
resource searchIndexDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.searchIndexDataContributor
}

resource miSearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, searchIndexDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: searchIndexDataContributor.id
    principalId: id
    description: 'searchIndexDataContributor for ${id}'
  }
}]

//Cosmos DB Data Contributor Role Assignments
resource cosmosDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbBuiltInDataContributor
}

resource miCosmosDataContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDataContributor.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDataContributor.id
    principalId: id
    description: 'cosmosDbBuiltInDataContributor for ${id}'
  }
}]

//Cosmos DB Operator Role Assignments
resource cosmosDbOperator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbOperator
}

resource miComsmosDbOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDbOperator.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDbOperator.id
    principalId: id
    description: 'cosmosDbOperator for ${id}'
  }
}]


//Cosmos DB Account Reader Role Assignments
resource cosmosDbAccountReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.cosmosDbAccountReader
}

resource miComsmosDbAccountReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, cosmosDbAccountReader.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cosmosDbAccountReader.id
    principalId: id
    description: 'cosmosDbAccountReader for ${id}'
  }
}]

//ACR Pull Role Assignments
resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roles.acrPull
}
resource miAcrPullAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in principalIds: {
  name: guid(id, acrPullRole.id, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: id
    description: 'acrPull for ${id}'
  }
}]

output principalIds array = principalIds


