param location string = resourceGroup().location
param containerAppEnvironmentName string
param containerRegistryName string
param containerApps array
param managedIdentityId string = ''
param sharedConfiguration array = []
param sharedKvSecrets array = []
param sharedKvSecretRefs array = []

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// Loop through all container apps and deploy them
module functionContainerApps 'container-app.bicep' = [for (app, i) in containerApps: {
  name: app.name
  params: {
    location: location
    containerAppEnvironmentName: containerAppEnvironmentName
    containerAppName: app.name
    containerImage: app.image
    containerRegistry: containerRegistry.properties.loginServer
    isExternalIngress: app.isExternalIngress
    containerPort: app.containerPort
    minReplicas: app.minReplicas
    maxReplicas: app.maxReplicas
    managedIdentityId: managedIdentityId
    env: concat(sharedConfiguration, app.env)
    secrets: sharedKvSecrets
    secretRefs :sharedKvSecretRefs
    cpuCore: app.cpuCore
    memorySize: app.memorySize
    queueName: app.queueName
    serviceBusNamespace: app.serviceBusNamespace
    useServiceBusScaleRule: app.useServiceBusScaleRule
    appDllName: app.appDllName
  }
}]

