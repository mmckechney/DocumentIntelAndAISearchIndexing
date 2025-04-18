param location string = resourceGroup().location
param processFunctionName string
param managedIdentityId string
param sharedConfiguration array
param containerAppEnvironmentId string
param containerAppSubnetId string 

resource processFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: processFunctionName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    virtualNetworkSubnetId: containerAppSubnetId
    managedEnvironmentId: containerAppEnvironmentId
    keyVaultReferenceIdentity:  managedIdentityId
    siteConfig: {
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: false
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'  // Fix the runtime identifier format
      remoteDebuggingEnabled: false
      //alwaysOn: funcAppPlanSku != 'Y1' // Enable for dedicated plans
      appSettings: concat(sharedConfiguration, [
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(replace(processFunctionName, '-', ''))  // Fix the content share name (no hyphens)
        }
      ])
    }
  }
}

output systemAssignedIdentity string = processFunction.identity.principalId
