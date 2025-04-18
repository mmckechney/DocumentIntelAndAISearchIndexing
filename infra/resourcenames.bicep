targetScope = 'subscription'

param appName string
param location string


resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
	name: resourceGroupName
  location: location
}

var resourceGroupName = '${abbrs.resourceGroup}${appName}-${location}'
var abbrs = loadJsonContent('./constants/abbreviations.json')
var appNameLc = toLower(appName)

output resourceGroupName string = resourceGroupName
output serviceBusNs string = '${abbrs.serviceBusNamespace}${appName}-${location}'
output formStorageAcct string = '${abbrs.storageAccount}${appNameLc}${location}'
output funcStorageAcct string = '${abbrs.storageAccount}${appNameLc}func${location}'
output formRecognizer string = '${abbrs.documentIntelligence}${appName}-${location}'

output vnet string = '${abbrs.virtualNetwork}${appName}-${location}'
output subnet string = '${abbrs.virtualNetworkSubnet}${appName}-${location}'
output nsg string = '${abbrs.networkSecurityGroup}${appName}-${location}'
output containerAppSubnet string = '${abbrs.virtualNetworkSubnet}${appName}-ca-${location}'
output apimsubnet string = '${abbrs.virtualNetworkSubnet}${appName}-apim-${location}'

output funcCustomField string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Custom-${location}')
output funcProcess string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Intell-${location}')
output funcMove string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Mover-${location}')
output funcQueue string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Queueing-${location}')
output aiSearchIndexFunctionName string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-AiSearch-${location}')
output askQuestionsFunctionName string = toLower('${abbrs.containerApp}${abbrs.functionApp}${appName}-Ask-${location}')

output keyvaultName string = '${abbrs.keyVault}${appName}-${location}'

output aiSearchName string = '${abbrs.aiSearch}${appNameLc}-demo-${location}'
output appInsightsName string = '${abbrs.applicationInsights}${appName}-${location}'
output logAnalyticsName string = '${abbrs.logAnalyticsWorkspace}${appName}-${location}'
output managedIdentityName string = '${abbrs.managedIdentity}${appName}-${location}'
output apiManagementName string = '${abbrs.apiManagementService}${appName}-${location}'

output cosmosDbName string = 'documentIndexing'
output cosmosContainerName string = 'processTracker'
output cosmosDbAccountName string = toLower('${abbrs.cosmosDBNoSQL}${appName}-${location}')

output documentStorageContainer string = 'documents'
output processResultsContainer string = 'processresults'
output completedContainer string = 'completed'

output customFieldQueueName string = 'customfieldqueue'
output docQueueName string = 'docqueue'
output moveQueueName string = 'movequeue'
output toIndexQueueName string = 'toindexqueue'

output openAiApiName string = 'openai'

output containerAppEnvName string = '${abbrs.containerAppsEnvironment}${appName}-${location}'
output containerRegistryName string = toLower('${abbrs.containerRegistry}${appNameLc}${location}')
output groupName string = rg.name  


