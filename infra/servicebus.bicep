
param serviceBusNs string
param formQueueName string
param processedQueueName string
param toIndexQueueName string
param location string = resourceGroup().location
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusNs
  location: location
  sku: {
    name: 'Standard'
  }
}

resource serviceBusFormQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  name: formQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: true
    maxSizeInMegabytes: 4096
  }
}

resource serviceBusProcessedQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  name: processedQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: true
    maxSizeInMegabytes: 4096
  }
}

resource serviceBusToIndexQueue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  name: toIndexQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: true
    maxSizeInMegabytes: 4096
  }
}

resource serviceBusAuthorizationRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2021-06-01-preview' = {
  name: 'FormProcessFuncRule'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

resource serviceBusConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'SERVICE-BUS-CONNECTION'
  parent: keyVault
  properties: {
    value: serviceBusAuthorizationRule.listKeys().primaryConnectionString
  }
}


output serviceBusId string = serviceBusNamespace.id
output authorizationRuleName string = serviceBusAuthorizationRule.name
