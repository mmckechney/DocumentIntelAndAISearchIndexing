
param serviceBusNs string
param docQueueName string
param moveQueueName string
param toIndexQueueName string
param customFieldQueueName string
param location string = resourceGroup().location
param serviceBusSku string = 'Standard' 
param vnetName string = ''
param subnetName string = ''

var enablePartitioning = (serviceBusSku != 'Premium')
var includeNetworking = (serviceBusSku == 'Premium')
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

resource serviceBusMoveQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: moveQueueName
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
output serviceBusFullyQualifiedNamespace string = '${serviceBusNs}.servicebus.windows.net'
