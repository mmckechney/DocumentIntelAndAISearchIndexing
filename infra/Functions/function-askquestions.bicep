param funcAppPlan string
param location string = resourceGroup().location
param askQuestionsFunctionName string
param functionSubnetId string
param managedIdentityId string
param useManagedIdentity bool 
param sharedConfiguration array



resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' existing = {
  name: funcAppPlan
}

resource askQuestions 'Microsoft.Web/sites@2021-01-01' = {
  name: askQuestionsFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: useManagedIdentity ? 'SystemAssigned, UserAssigned' : 'SystemAssigned'
    userAssignedIdentities: useManagedIdentity ? {
      '${managedIdentityId}': {}
    } : null
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: functionAppPlan.id
    keyVaultReferenceIdentity: useManagedIdentity ? managedIdentityId : 'SystemAssigned'
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: false
      appSettings: sharedConfiguration 

    }
  }
}

output systemAssignedIdentity string = askQuestions.identity.principalId
