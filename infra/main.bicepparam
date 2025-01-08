using './main.bicep'
param location = ''
param appName = ''
param currentUserObjectId = ''
param myPublicIp = ''
param loadBalancingType = 'round-robin'
param serviceBusSku = 'Standard'

param docIntelligenceInstanceCount = 2

param apiManagementPublisherEmail = 'mimcke@microsoft.com'
param apiManagementPublisherName = 'Michael Mimcke'

param azureOpenAIEmbeddingModel = 'text-embedding-ada-002'
param embeddingMaxTokens = 2048
param embeddingModelVersion = '2'

param azureOpenAIChatModel = 'gpt-4o'
param chatModelVersion = '2024-08-06'




//ADd info on each Azure OpenAI instance to deploy
var eastUs2 = {
    name: ''
    location: 'eastus2'
    suffix: 'eastus2'
    priority: 1
}

var swedencentral = {
    name: ''
    location: 'swedencentral'
    suffix: 'swedencentral'
    priority: 2
}

var westus3 = {
    name: ''
    location: 'westus3'
    suffix: 'westus3'
    priority: 2
}

param openAIInstances = [
    eastUs2
    swedencentral
    westus3  
]




