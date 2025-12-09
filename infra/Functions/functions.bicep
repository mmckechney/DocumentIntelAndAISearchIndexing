import * as customTypes from '../constants/customTypes.bicep'

param location string = resourceGroup().location
param functionValues customTypes.functionValue[]
param managedEnvironmentId string
param containerRegistryServer string
@description('Identity used by the Container Apps runtime to pull from the registry. Typically the user-assigned managed identity id.')
param containerRegistryIdentityResourceId string
param managedIdentityId string
param managedIdentityClientId string
param formStorageAcctName string
param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param serviceBusNs string
param docQueueName string
param customFieldQueueName string
param moveQueueName string
param toIndexQueueName string
param openAiEmbeddingModel string
param aiSearchEndpoint string
param openAiEndpoint string
param cosmosDbEndpoint string
param serviceBusFullyQualifiedNamespace string
param documentIntelligenceEndpoint string
param documentIntelligenceEndpoints string
param azureOpenAiEmbeddingMaxTokens int = 8091
param aiIndexName string
param openAiChatModel string
param cosmosDbName string
param cosmosContainerName string
param appInsightsConnectionString string
param appInsightsInstrumentationKey string

var configKeys = loadJsonContent('../constants/configKeys.json')

var ingressConfiguration = {
  'askquestions-app': {
    external: true
    targetPort: 8080
    transport: 'auto'
    allowInsecure: false
    traffic: [
      {
        latestRevision: true
        weight: 100
      }
    ]
  }
  'queueing-app': {
    external: true
    targetPort: 8080
    transport: 'auto'
    allowInsecure: false
    traffic: [
      {
        latestRevision: true
        weight: 100
      }
    ]
  }
}

var normalizedFunctionValuesBase = [for functionValue in functionValues: {
  name: toLower(functionValue.name)
  tag: functionValue.tag
  serviceName: empty(functionValue.serviceName ?? '') ? toLower(functionValue.name) : (functionValue.serviceName ?? toLower(functionValue.name))
}]

var normalizedFunctionValues = [for functionValue in normalizedFunctionValuesBase: union(functionValue, {
  hasIngress: contains(ingressConfiguration, functionValue.serviceName)
})]

var sharedConfiguration = [
  {
    name: configKeys.COSMOS_ACCOUNT_ENDPOINT
    value: cosmosDbEndpoint
  }
  {
    name: configKeys.COSMOS_DB_NAME
    value: cosmosDbName
  }
  {
    name: configKeys.COSMOS_CONTAINER_NAME
    value: cosmosContainerName
  }
  {
    name: configKeys.STORAGE_ACCOUNT_NAME
    value: formStorageAcctName
  }
  {
    name: configKeys.STORAGE_SOURCE_CONTAINER_NAME
    value: documentStorageContainer
  }
  {
    name: configKeys.STORAGE_PROCESS_RESULTS_CONTAINER_NAME
    value: processResultsContainer
  }
  {
    name: configKeys.STORAGE_COMPLETED_CONTAINER_NAME
    value: completedContainer
  }
  {
    name: configKeys.SERVICEBUS_NAMESPACE_NAME
    value: serviceBusNs
  }
  {
    name: configKeys.SERVICEBUS_DOC_QUEUE_NAME
    value: docQueueName
  }
  {
    name: configKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME
    value: customFieldQueueName
  }
  {
    name: configKeys.SERVICEBUS_TOINDEX_QUEUE_NAME
    value: toIndexQueueName
  }
  {
    name: configKeys.SERVICEBUS_MOVE_QUEUE_NAME
    value: moveQueueName
  }
  {
    name: configKeys.AZURE_AISEARCH_ENDPOINT
    value: aiSearchEndpoint
  }
  {
    name: configKeys.AZURE_AISEARCH_INDEX_NAME
    value: aiIndexName
  }
  {
    name: configKeys.AZURE_OPENAI_ENDPOINT
    value: openAiEndpoint
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_MODEL
    value: openAiEmbeddingModel
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_DEPLOYMENT
    value: openAiEmbeddingModel
  }
  {
    name: configKeys.AZURE_OPENAI_CHAT_MODEL
    value: openAiChatModel
  }
  {
    name: configKeys.AZURE_OPENAI_CHAT_DEPLOYMENT
    value: openAiChatModel
  }
  {
    name: configKeys.AZURE_OPENAI_EMBEDDING_MAXTOKENS
    value: string(azureOpenAiEmbeddingMaxTokens)
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_MODEL_NAME
    value: 'prebuilt-layout'
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_ENDPOINT
    value: documentIntelligenceEndpoint
  }
  {
    name: configKeys.DOCUMENT_INTELLIGENCE_ENDPOINTS
    value: documentIntelligenceEndpoints
  }
]

var containerRuntimeConfiguration = concat(sharedConfiguration, [
  {
    name: '${configKeys.SERVICEBUS_CONNECTION}__fullyQualifiedNamespace'
    value: serviceBusFullyQualifiedNamespace
  }
  {
    name: '${configKeys.SERVICEBUS_CONNECTION}__credential'
    value: 'ManagedIdentity'
  }
  {
    name: '${configKeys.SERVICEBUS_CONNECTION}__clientId'
    value: managedIdentityClientId
  }
  {
    name: 'MANAGED_IDENTITY_CLIENT_ID'
    value: managedIdentityClientId
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsInstrumentationKey
  }
])

resource containerApps 'Microsoft.App/containerApps@2023-05-01' = [for functionValue in normalizedFunctionValues: {
  name: functionValue.name
  location: location
  tags: {
    'azd-service-name': functionValue.serviceName
    'workload-role': functionValue.tag
  }
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironmentId
    configuration: union({
      secrets: []
      registries: [
        {
          server: containerRegistryServer
          identity: containerRegistryIdentityResourceId
        }
      ]
    }, functionValue.hasIngress ? {
      ingress: ingressConfiguration[functionValue.serviceName]
    } : {})
    template: {
      containers: [
        {
          name: functionValue.serviceName
          image: '${containerRegistryServer}/${functionValue.serviceName}:latest'
          env: containerRuntimeConfiguration
          resources: {
            cpu: functionValue.hasIngress ? json('1.0') : json('0.5')
            memory: functionValue.hasIngress ? '2Gi' : '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: functionValue.hasIngress ? 3 : 2
      }
    }
  }
}]

output systemAssignedIdentities array = [for (functionValue, index) in normalizedFunctionValues: containerApps[index].identity.principalId]
output services array = [for (functionValue, index) in normalizedFunctionValues: {
  serviceName: functionValue.serviceName
  containerAppName: containerApps[index].name
  containerAppResourceId: containerApps[index].id
  ingressFqdn: functionValue.hasIngress ? reference(containerApps[index].id, '2023-05-01', 'full').properties.configuration.ingress.fqdn : ''
}]

