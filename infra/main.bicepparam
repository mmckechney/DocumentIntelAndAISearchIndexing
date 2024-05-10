using './main.bicep'
param location = ''
param appName = ''
param currentUserObjectId = ''
param myPublicIp = ''
param loadBalancingType = 'round-robin'
param serviceBusSku = 'Standard'

param docIntelligenceInstanceCount = 2

param apiManagementPublisherEmail = 'test@email.com'
param apiManagementPublisherName = 'Me'

param azureOpenAIEmbeddingModel = 'text-embedding-ada-002'
param embeddingMaxTokens = 2048
param embeddingModelVersion = '2'

param azureOpenAIChatModel = 'gpt-35-turbo-16k'
param chatModelVersion = '0613'




//ADd info on each Azure OpenAI instance to deploy
var eastUs = {
    name: ''
    location: 'eastus'
    suffix: 'eastus'
    priority: 1
}

var eastus2 = {
    name: ''
    location: 'eastus2'
    suffix: 'eastus2'
    priority: 2
}

var canadaEast = {
    name: ''
    location: 'canadaeast'
    suffix: 'canadaeast'
    priority: 2
}

param openAIInstances = [
    eastUs
    eastus2
    canadaEast  
]




