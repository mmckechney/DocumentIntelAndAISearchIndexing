param location string = resourceGroup().location
param aiSearchIndexFunctionName string
param managedIdentityId string 
param containerAppEnvironmentId string
param containerAppSubnetId string 
param sharedConfiguration array


resource aiSearchIndexFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: aiSearchIndexFunctionName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities:  {
      '${managedIdentityId}': {}
    } 
  }
  properties: {
    virtualNetworkSubnetId: containerAppSubnetId
    managedEnvironmentId: containerAppEnvironmentId
    keyVaultReferenceIdentity: managedIdentityId 
    siteConfig: {
      acrUseManagedIdentityCreds: true
      
      cors: {
        allowedOrigins: ['https://portal.azure.com', 'https://ms.portal.azure.com']
      }
      use32BitWorkerProcess: false
      remoteDebuggingEnabled: false
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'  // Specify .NET 8.0 runtime for Linux
      
      appSettings: concat(sharedConfiguration, [
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(replace(aiSearchIndexFunctionName, '-', '')) 
        }
      ])
    }

  }
}

output systemAssignedIdentity string = aiSearchIndexFunction.identity.principalId
