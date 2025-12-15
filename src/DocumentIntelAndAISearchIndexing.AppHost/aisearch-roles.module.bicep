@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

param aisearch_outputs_name string

param principalType string

param principalId string

resource aisearch 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: aisearch_outputs_name
}

resource aisearch_SearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aisearch.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8ebe5a00-799e-43f5-93ac-243d3dce84a7'))
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8ebe5a00-799e-43f5-93ac-243d3dce84a7')
    principalType: principalType
  }
  scope: aisearch
}

resource aisearch_SearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aisearch.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0'))
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
    principalType: principalType
  }
  scope: aisearch
}