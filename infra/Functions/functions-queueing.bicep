param funcAppPlan string
param location string = resourceGroup().location
param functionSubnetId string
param queueFunctionName string
param managedIdentityId string
param useManagedIdentity bool 
param sharedConfiguration array

resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' existing = {
  name: funcAppPlan
}


resource queueingFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: queueFunctionName
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
    keyVaultReferenceIdentity: useManagedIdentity ? managedIdentityId : ''
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

output systemAssignedIdentity string = queueingFunction.identity.principalId
