param location string = resourceGroup().location
param containerAppEnvironmentName string
param containerAppName string
param containerImage string
param containerRegistry string
param isExternalIngress bool = false
param containerPort int = 80
param minReplicas int = 1
param maxReplicas int = 10
param managedIdentityId string = ''
param env array = []
param secrets array = []
param secretRefs array = []
param cpuCore string = '0.5'
param memorySize string = '1.0Gi'
param revisionMode string = 'Single'
param workloadProfileName string = 'Consumption'
param useServiceBusScaleRule bool
param serviceBusNamespace string
param queueName string
param appDllName string
param messageCount int = 100

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

var envAndSecretRefs = concat(env, secretRefs)

var httpProbe = [  
  {
    type: 'Readiness'
    httpGet: {
       port: 8080
       path: '/health'
    }
    initialDelaySeconds: 10
    periodSeconds: 5
    failureThreshold: 30
  }
]

resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvironmentName
}

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  identity:  {
    type:  'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    workloadProfileName: workloadProfileName
    configuration: {
      secrets: secrets
      activeRevisionsMode: revisionMode
      ingress: isExternalIngress ? {
        external: true
        targetPort: containerPort
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      } : null
      registries: [
        { 
          identity: managedIdentityId
          server: containerRegistry
          username: ''
        }
       ] 
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          env: envAndSecretRefs
          resources: {
            cpu: json(cpuCore)
            memory: memorySize
          }
          args:[
            'dotnet'
             appDllName
          ]
          probes: (isExternalIngress)? httpProbe : []
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules:  (useServiceBusScaleRule) ? [
          {
            name: 'service-bus-scale-rule'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                namespace: serviceBusNamespace 
                queueName: queueName
                messageCount: string(messageCount)
              }
              auth: [
                {
                  secretRef: toLower(keyVaultKeys.SERVICEBUS_CONNECTION)
                  triggerParameter: 'connection'
                  
                }
              ]
              identity: managedIdentityId
            }
            
          }
        ] :[
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = isExternalIngress ? containerApp.properties.configuration.ingress.fqdn : ''
output name string = containerApp.name
