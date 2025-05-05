param funcAppPlanId string
param location string = resourceGroup().location
param functionName string
param functionTag string
param functionSubnetId string
param managedIdentityId string
param sharedConfiguration array


resource function 'Microsoft.Web/sites@2021-01-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  tags: {
    'azd-service-name': functionTag
  }
  properties: {
    virtualNetworkSubnetId: functionSubnetId
    serverFarmId: funcAppPlanId
    keyVaultReferenceIdentity: managedIdentityId 
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'
        ]
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      remoteDebuggingEnabled: false
      appSettings: sharedConfiguration
    }
  }
}

output systemAssignedIdentity string = function.identity.principalId
