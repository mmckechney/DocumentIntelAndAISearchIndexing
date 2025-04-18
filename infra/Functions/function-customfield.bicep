
param location string = resourceGroup().location
param customFieldFunctionName string
param managedIdentityId string
param sharedConfiguration array
param containerAppEnvironmentId string
param containerAppSubnetId string 

resource processFunction 'Microsoft.Web/sites@2022-09-01' ={
  name: customFieldFunctionName
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
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'  // Specify .NET 8.0 runtime for Linux
      remoteDebuggingEnabled: false
      appSettings: concat(sharedConfiguration, [
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(replace(customFieldFunctionName, '-', '')) 
        }
      ])
    }
  }
}

output systemAssignedIdentity string = processFunction.identity.principalId
