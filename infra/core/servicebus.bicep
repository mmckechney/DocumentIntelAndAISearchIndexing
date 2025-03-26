
param serviceBusNs string
param docQueueName string
param processedQueueName string
param toIndexQueueName string
param customFieldQueueName string
param location string = resourceGroup().location
param keyVaultName string
param serviceBusSku string = 'Standard' 
param vnetName string = ''
param subnetName string = ''

var enablePartitioning = (serviceBusSku != 'Premium')
var includeNetworking = (serviceBusSku == 'Premium')

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNs
  location: location
  sku: {
    name: serviceBusSku
  }

}

resource serviceBusDocQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: docQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: enablePartitioning
    maxSizeInMegabytes: 4096
  }
}

resource serviceBusProcessedQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: processedQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: enablePartitioning
    maxSizeInMegabytes: 4096
  }
}

resource serviceBusToIndexQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: toIndexQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: enablePartitioning
    maxSizeInMegabytes: 4096
  }
}
resource serviceBusCustomFieldQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: customFieldQueueName
  parent: serviceBusNamespace
  properties: {
    enablePartitioning: enablePartitioning
    maxSizeInMegabytes: 4096
  }
}


resource serviceBusAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: 'FormProcessFuncRule'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

resource serviceBusConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'SERVICE-BUS-CONNECTION'
  parent: keyVault
  properties: {
    value: serviceBusAuthorizationRule.listKeys().primaryConnectionString
  }
}

resource serviceBusNamespaceNetworkRuleSet 'Microsoft.ServiceBus/namespaces/networkRuleSets@2021-06-01-preview' = if(includeNetworking) {
  parent: serviceBusNamespace
  name: 'default'
  properties: {
    defaultAction: 'Deny'
    trustedServiceAccessEnabled: true
    virtualNetworkRules:  [
      {
        subnet: {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
        }
        ignoreMissingVnetServiceEndpoint: false
      }
    ]
  }
}

output serviceBusId string = serviceBusNamespace.id
output authorizationRuleName string = serviceBusAuthorizationRule.name
