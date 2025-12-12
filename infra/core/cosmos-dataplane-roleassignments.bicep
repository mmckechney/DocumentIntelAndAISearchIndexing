
@description('Cosmos DB account name')
param accountName string

@description('AAD objectId of the principal to grant data access (user, SPN, or managed identity)')
param principalIds array

@description('Resource group of the Cosmos account')
param cosmosRg string

var subscriptionId = subscription().subscriptionId

// Reference the existing Cosmos DB account
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: accountName
}

// Built-in data-plane role IDs
var cosmosDataRoles = {
  reader: '00000000-0000-0000-0000-000000000001'
  contributor: '00000000-0000-0000-0000-000000000002'
}

// Assign the built-in Data Contributor at the *account* scope
resource dataContributorAtAccount 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = [for id in principalIds: {
   name: guid(cosmosAccount.id, id, 'account-scope-contributor')
  parent: cosmosAccount
  properties: {
    // Role definition lives under the Cosmos account provider, not Microsoft.Authorization
    roleDefinitionId: '/subscriptions/${subscriptionId}/resourceGroups/${cosmosRg}/providers/Microsoft.DocumentDB/databaseAccounts/${accountName}/sqlRoleDefinitions/${cosmosDataRoles.contributor}'
    principalId: id
    scope: cosmosAccount.id
  }
}
]

// Assign the built-in Data Reader at the *account* scope
resource dataReaderAtAccount 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = [for id in principalIds: {
   name: guid(cosmosAccount.id, id, 'account-scope-reader')
  parent: cosmosAccount
  properties: {
    // Role definition lives under the Cosmos account provider, not Microsoft.Authorization
    roleDefinitionId: '/subscriptions/${subscriptionId}/resourceGroups/${cosmosRg}/providers/Microsoft.DocumentDB/databaseAccounts/${accountName}/sqlRoleDefinitions/${cosmosDataRoles.reader}'
    principalId: id
    scope: cosmosAccount.id
  }
}
]
