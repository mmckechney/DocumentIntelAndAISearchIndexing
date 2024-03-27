param storageAccountName string
param docIntelligencePrincipalIds array
param processFunctionId string
param moveFunctionId string
param queueFunctionId string
param aiSearchIndexFunctionId string
param currentUserObjectId string 



var storageAccountBlobDataContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // role definition ID for "Storage Account Blob Data Contributor"
var storageAccountBlobbDataOwnerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b') // role definition ID for "Storage Account Blob Data Owner"
var serviceBusDataOwnerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419') // role definition ID for "Service Bus Data Owner"
var storageAccountBlobDataReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // role definition ID for "Storage Account Blob Data Reader"
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // role definition ID for "Key Vault Secrets Owner"
var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
resource storageAcct 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

//Document Intelligence Accounts 
resource docIntelligenceBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for id in docIntelligencePrincipalIds: {
  name: guid(id, storageAccountBlobDataReaderRoleDefinitionId, deploymentEntropy)
  scope: storageAcct
  properties: {
    roleDefinitionId: storageAccountBlobDataReaderRoleDefinitionId
    principalId: id
    
  }
}]


// Process function
resource processFuncBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(processFunctionId, storageAccountBlobDataContributorRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobDataContributorRoleDefinitionId
    principalId: processFunctionId
    
  }
}

resource processFuncBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(processFunctionId, storageAccountBlobbDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobbDataOwnerRoleDefinitionId
    principalId: processFunctionId
    
  }
}

resource processFuncSbDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(processFunctionId, serviceBusDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinitionId
    principalId: processFunctionId
    
  }
}

resource processFuncKvUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(processFunctionId, keyVaultSecretsUserRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: processFunctionId
    
  }
}


// Mover Function
resource moverFuncBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(moveFunctionId, storageAccountBlobDataContributorRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobDataContributorRoleDefinitionId
    principalId: moveFunctionId
    
  }
}

resource moverFuncBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name:  guid(moveFunctionId, storageAccountBlobbDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobbDataOwnerRoleDefinitionId
    principalId: moveFunctionId
    
  }
}

resource moverFuncSbDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name:  guid(moveFunctionId, serviceBusDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinitionId
    principalId: moveFunctionId
    
  }
}

resource moverFuncKvUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(moveFunctionId, keyVaultSecretsUserRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: moveFunctionId
    
  }
}

// Ai Search Index Function
resource aiSearchFuncKvUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aiSearchIndexFunctionId, keyVaultSecretsUserRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: aiSearchIndexFunctionId
    
  }
}

resource aiSearchFuncSbDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aiSearchIndexFunctionId, serviceBusDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinitionId
    principalId: aiSearchIndexFunctionId
    
  }
}

resource aiSearchFuncBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aiSearchIndexFunctionId, storageAccountBlobDataContributorRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobDataContributorRoleDefinitionId
    principalId: aiSearchIndexFunctionId
    
  }
}

resource aiSearchFuncBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name:guid(aiSearchIndexFunctionId, storageAccountBlobbDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobbDataOwnerRoleDefinitionId
    principalId: aiSearchIndexFunctionId
    
  }
}



//queue function
resource queueFuncBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(queueFunctionId, storageAccountBlobDataContributorRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobDataContributorRoleDefinitionId
    principalId: queueFunctionId
    
  }
}

resource queueFuncBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name:guid(queueFunctionId, storageAccountBlobbDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobbDataOwnerRoleDefinitionId
    principalId: queueFunctionId
    
  }
}

resource queueFuncSbDataOwner 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(queueFunctionId, serviceBusDataOwnerRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: serviceBusDataOwnerRoleDefinitionId
    principalId: queueFunctionId
    
  }
}

//Current user 
resource currentUserKvUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(currentUserObjectId, keyVaultSecretsUserRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: currentUserObjectId
    
  }
}

resource currentUserBlobDataContrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(currentUserObjectId, storageAccountBlobDataContributorRoleDefinitionId, deploymentEntropy)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageAccountBlobDataContributorRoleDefinitionId
    principalId: currentUserObjectId
    
  }
}

resource currentUserBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' =  {
  name: guid(currentUserObjectId, storageAccountBlobDataReaderRoleDefinitionId, deploymentEntropy)
  scope: storageAcct
  properties: {
    roleDefinitionId: storageAccountBlobDataReaderRoleDefinitionId
    principalId: currentUserObjectId
    
  }
}

