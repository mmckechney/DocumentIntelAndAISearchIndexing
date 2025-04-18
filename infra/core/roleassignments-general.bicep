param principalIds object
param cosmosDbAccountName string

var deploymentEntropy = '3F2504E0-4F89-11D3-9A0C-0305E82C3302'
var roles = loadJsonContent('../constants/roles.json')

var keyRoles = [  
    roles.storageBlobDataContributor
    roles.storageBlobDataOwner
    roles.serviceBusDataOwner
    roles.keyVaultSecretsUser
    roles.aiSearchDataContributor
    roles.aiSearchServiceContributor
  ]


  resource keyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for role in keyRoles:  {
    name: guid(principalIds.id , role.roleId, deploymentEntropy)
    scope: resourceGroup()
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.roleId)
      principalId: principalIds.id
      description: '${principalIds.name}-${role.name}'
    }
  }]

  resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
    scope: resourceGroup()
    name: cosmosDbAccountName
  }
  
  resource cosmosDbDataReaderAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-12-01-preview'= {
    name: guid(principalIds.id , roles.cosmosDbDataReader.roleId, deploymentEntropy)
    parent: cosmosDbAccount
    properties: {
      roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDbAccountName, roles.cosmosDbDataReader.roleId)
      principalId: principalIds.id
      scope: cosmosDbAccount.id
    }
  }
  
  resource cosmosDbDataContributorAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-12-01-preview' = {
    name: guid(principalIds.id , roles.cosmosDbDataContributor.roleId, deploymentEntropy)
    parent: cosmosDbAccount
    properties: {
      roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDbAccountName, roles.cosmosDbDataContributor.roleId)
      principalId: principalIds.id
      scope: cosmosDbAccount.id
    }
  }
