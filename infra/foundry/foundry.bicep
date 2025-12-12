param aiFoundryResourceName string
param location string = resourceGroup().location
param tags object = {}
param managedIdentityId string
param projectName string
param chatModelName string
param chatModelVersion string
param chatSku string = 'Standard'
param chatCapacity int = 1
param embeddingModelName string
param embeddingModelVersion string
param embeddingSku string = 'Standard'
param embeddingCapacity int = 1

@secure()
param appInsightsConnectionString string
param appInsightsResourceId string

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
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
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

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-07-01-preview' = {
  name: projectName
  parent: aiFoundryResource
  location: location
   identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
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

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: 'ApplicationInsights'
  properties: {
    category: 'AppInsights'
    authType: 'ApiKey'
    target: appInsightsResourceId
    credentials: {
      key: appInsightsConnectionString
    }
     
    metadata: {
      connectionString: appInsightsConnectionString

    }
    useWorkspaceManagedIdentity: false
    peRequirement: 'NotApplicable'
  }
}

output accountName string = aiFoundryResource.name
output accountId string = aiFoundryResource.id
output projectResourceName string = foundryProject.name
output projectEndpoint string = foundryProject.properties.endpoints['AI Foundry API']
output servicesEndpointHost string = servicesEndpoint
output chatDeploymentName string = chatDeployment.name
output embeddingDeploymentName string = embeddingDeployment.name
output embeddingModel string = embeddingModelName
output chatModel string = chatModelName
