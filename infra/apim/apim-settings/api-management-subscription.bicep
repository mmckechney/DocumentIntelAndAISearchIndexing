@description('Name of the Subscription.')
param name string
@description('Name of the API Management associated with the Subscription.')
param apiManagementName string
@description('Display name of the Subscription.')
param displayName string
@description('Scope of the Subscription (e.g., /products or /apis) associated with the API Management resource.')
param scope string
param keyVaultName string

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementName
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2023-05-01-preview' = {
  parent: apiManagement
  name: name
  properties: {
    displayName: displayName
    scope: scope
    state: 'active'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  
}
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'APIM-SUBSCRIPTION-KEY'
  properties: {
    value: subscription.listSecrets().primaryKey
  }
}


@description('ID for the deployed API Management Subscription resource.')
output id string = subscription.id
@description('Name for the deployed API Management Subscription resource.')
output name string = subscription.name

