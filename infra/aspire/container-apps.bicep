param environmentId string
param location string
param managedIdentityId string
param containerRegistryName string
param aiSearchEndpoint string
param aiSearchIndexName string
param serviceBusNamespace string
param storageAccountName string
param cosmosDbName string
param cosmosContainerName string
param cosmosDbAccountName string
param openAiEndpoint string
param openAiChatModel string
param openAiEmbeddingModel string
param appInsightsConnectionString string
param keyVaultName string

var containerImageTag = 'latest'

// Reference existing resources
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: last(split(managedIdentityId, '/'))
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespace
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: cosmosDbAccountName
}

resource environment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: last(split(environmentId, '/'))
}

// Common environment variables for all container apps
var commonEnvVars = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Production'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
  }
  {
    name: 'SERVICEBUS_CONNECTION'
    value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
  }
  {
    name: 'SERVICEBUS_NAMESPACE_NAME'
    value: serviceBusNamespace
  }
  {
    name: 'SERVICEBUS_DOC_QUEUE_NAME'
    value: 'docqueue'
  }
  {
    name: 'SERVICEBUS_MOVE_QUEUE_NAME'
    value: 'movequeue'
  }
  {
    name: 'SERVICEBUS_TOINDEX_QUEUE_NAME'
    value: 'toindexqueue'
  }
  {
    name: 'SERVICEBUS_CUSTOMFIELD_QUEUE_NAME'
    value: 'customfieldqueue'
  }
  {
    name: 'COSMOS_CONNECTION'
    value: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
  {
    name: 'COSMOS_DB_NAME'
    value: cosmosDbName
  }
  {
    name: 'COSMOS_CONTAINER_NAME'
    value: cosmosContainerName
  }
  {
    name: 'AZURE_OPENAI_ENDPOINT'
    value: openAiEndpoint
  }
  {
    name: 'AZURE_OPENAI_CHAT_MODEL'
    value: openAiChatModel
  }
  {
    name: 'AZURE_OPENAI_EMBEDDING_MODEL'
    value: openAiEmbeddingModel
  }
  {
    name: 'AZURE_AISEARCH_ENDPOINT'
    value: aiSearchEndpoint
  }
  {
    name: 'AZURE_AISEARCH_INDEX_NAME'
    value: aiSearchIndexName
  }
  {
    name: 'STORAGE_SOURCE_CONTAINER_NAME'
    value: 'documents'
  }
  {
    name: 'STORAGE_PROCESS_RESULTS_CONTAINER_NAME'
    value: 'processresults'
  }
  {
    name: 'STORAGE_COMPLETED_CONTAINER_NAME'
    value: 'completed'
  }
  {
    name: 'KeyVaultEndpoint'
    value: keyVault.properties.vaultUri
  }
]

// App Host
resource appHostContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'doc-intel-apphost'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'doc-intel-apphost'
          image: '${containerRegistry.properties.loginServer}/doc-intel-apphost:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// AI Search Indexing Function
resource aiSearchIndexingContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'aisearch-indexing'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'aisearch-indexing'
          image: '${containerRegistry.properties.loginServer}/aisearch-indexing:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'toindexqueue'
                namespace: serviceBusNamespace
                messageCount: '5'
              }
              auth: [
                {
                  secretRef: 'sb-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Document Intelligence Function
resource docIntelligenceContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'doc-intelligence'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'doc-intelligence'
          image: '${containerRegistry.properties.loginServer}/doc-intelligence:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'docqueue'
                namespace: serviceBusNamespace
                messageCount: '5'
              }
              auth: [
                {
                  secretRef: 'sb-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Document Queueing Function
resource docQueueingContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'doc-queueing'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'doc-queueing'
          image: '${containerRegistry.properties.loginServer}/doc-queueing:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
}

// Document Questions Function
resource docQuestionsContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'doc-questions'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'doc-questions'
          image: '${containerRegistry.properties.loginServer}/doc-questions:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
}

// Custom Field Extraction Function
resource customFieldExtractionContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'customfield-extraction'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'customfield-extraction'
          image: '${containerRegistry.properties.loginServer}/customfield-extraction:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'customfieldqueue'
                namespace: serviceBusNamespace
                messageCount: '5'
              }
              auth: [
                {
                  secretRef: 'sb-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Processed File Mover Function
resource fileMoverContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'file-mover'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'file-mover'
          image: '${containerRegistry.properties.loginServer}/file-mover:${containerImageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: commonEnvVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'movequeue'
                namespace: serviceBusNamespace
                messageCount: '5'
              }
              auth: [
                {
                  secretRef: 'sb-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Service Bus connection string for autoscaling
resource sbConnectionSecret 'Microsoft.App/managedEnvironments/secrets@2023-05-01' = {
  name: 'sb-connection-string'
  parent: environment
  properties: {
    value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
  }
}

output appHostUrl string = appHostContainerApp.properties.configuration.ingress.fqdn
output queueingUrl string = docQueueingContainerApp.properties.configuration.ingress.fqdn
output questionsUrl string = docQuestionsContainerApp.properties.configuration.ingress.fqdn
