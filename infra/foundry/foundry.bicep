param aiFoundryResourceName string
param location string = resourceGroup().location
param tags object = {}
param managedIdentityId string
param projectName string
param projectDisplayName string
param chatModelName string
param chatModelVersion string
param chatSku string = 'Standard'
param chatCapacity int = 1
param embeddingModelName string
param embeddingModelVersion string
param embeddingSku string = 'Standard'
param embeddingCapacity int = 1

var customSubdomain = toLower(aiFoundryResourceName)
var servicesEndpoint = 'https://${customSubdomain}.services.ai.azure.com'


resource aiFoundryResource 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryResourceName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {}
    customSubDomainName: customSubdomain
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    allowProjectManagement: true
    defaultProject: projectName
    associatedProjects: [
      projectName
    ]
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-07-01-preview' = {
  name: projectName
  parent: aiFoundryResource
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}



resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  name: chatModelName
  parent: aiFoundryResource
  sku: {
    name: chatSku
    capacity: chatCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: chatModelName
      version: chatModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  name: embeddingModelName
  parent: aiFoundryResource
  sku: {
    name: embeddingSku
    capacity: embeddingCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: embeddingModelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
    raiPolicyName: 'Microsoft.DefaultV2'
  }
  dependsOn: [
    chatDeployment
  ]
}


output accountName string = aiFoundryResource.name
output accountId string = aiFoundryResource.id
output projectResourceName string = project.name
output projectEndpoint string = project.properties.endpoints['AI Foundry API']
output servicesEndpointHost string = servicesEndpoint
output chatDeploymentName string = chatDeployment.name
output embeddingDeploymentName string = embeddingDeployment.name
output embeddingModel string = embeddingModelName
output chatModel string = chatModelName
