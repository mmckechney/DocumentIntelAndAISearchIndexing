param appName string
param location string
param appNameLc string
param abbrs object
param logAnalyticsName string
param appInsights string
param rg string
param managedIdentity string
param formStorageAcct string
param aiIndexName string
param serviceBusNs string
param docQueueName string
param moveQueueName string
param toIndexQueueName string
param customFieldQueueName string
param keyVaultName string
param serviceBusSku string
param cosmosDbName string
param cosmosContainerName string
param cosmosDbAccountName string
param apiManagement string
param azureOpenAIChatModel string
param azureOpenAIEmbeddingModel string
param funcsubnet string
param vnet string
param aiSearchEndpoint string

// Reference existing resources
resource rgResource 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: rg
  scope: subscription()
}

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsights
  scope: rgResource
}

resource managedIdentityResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: last(split(managedIdentity, '/'))
  scope: rgResource
}

resource apiManagementResource 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagement
  scope: rgResource
}


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnet
  scope: rgResource
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
  scope: rgResource
}


// Container Apps Environment for hosting Aspire applications
module containerAppsEnvironment 'core/container-apps-env.bicep' = {
  name: 'containerAppsEnvironment'
  scope: rgResource
  params: {
    name: '${abbrs.containerAppsEnvironment}${appName}-${location}'
    location: location
    logAnalyticsWorkspaceName: logAnalyticsName
    appInsightsName: appInsightsResource.name
  }
  dependsOn: [
    appInsightsResource
  ]
}

// Service Bus for inter-service communication
module aspireServiceBus 'core/servicebus.bicep' = {
  name: 'aspireServiceBus'
  scope: rgResource
  params: {
    serviceBusNs: serviceBusNs
    location: location
    docQueueName: docQueueName
    moveQueueName: moveQueueName
    toIndexQueueName: toIndexQueueName
    customFieldQueueName: customFieldQueueName
    keyVaultName: keyVaultName
    subnetName: funcsubnet
    vnetName: vnet
    serviceBusSku: serviceBusSku
  }
  dependsOn: [
    keyvault
    virtualNetwork
  ]
}

// Add Container Registry for container images
module containerRegistry 'core/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: rgResource
  params: {
    name: '${abbrs.containerRegistry}${replace(appNameLc, '-', '')}${location}'
    location: location
    adminUserEnabled: true
    managedIdentityName: managedIdentityResource.name
  }
  dependsOn: [
    managedIdentityResource
  ]
}

// Deploy Aspire orchestrated container apps
module aspireContainerApps 'aspire/container-apps.bicep' = {
  name: 'aspireContainerApps'
  scope: rgResource
  params: {
    environmentId: containerAppsEnvironment.outputs.id
    location: location
    managedIdentityId: managedIdentityResource.id
    containerRegistryName: containerRegistry.outputs.name
    aiSearchEndpoint: aiSearchEndpoint
    aiSearchIndexName: aiIndexName
    serviceBusNamespace: serviceBusNs
    storageAccountName: formStorageAcct
    cosmosDbName: cosmosDbName
    cosmosContainerName: cosmosContainerName
    cosmosDbAccountName: cosmosDbAccountName
    openAiEndpoint: apiManagementResource.properties.gatewayUrl
    openAiChatModel: azureOpenAIChatModel
    openAiEmbeddingModel: azureOpenAIEmbeddingModel
    appInsightsConnectionString: appInsightsResource.properties.ConnectionString
    keyVaultName: keyVaultName
  }
  dependsOn: [
    aspireServiceBus
  ]
}



output appHostUrl string = aspireContainerApps.outputs.appHostUrl
output queueingUrl string = aspireContainerApps.outputs.queueingUrl
output questionsUrl string = aspireContainerApps.outputs.questionsUrl
