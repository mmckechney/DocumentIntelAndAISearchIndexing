using './main.bicep'
param location = ''
param appName = ''
param currentUserObjectId = ''
param myPublicIp = ''
param loadBalancingType = 'round-robin'

param docIntelligenceInstanceCount = 2

param apiManagementPublisherEmail = 'test@email.com'
param apiManagementPublisherName = 'Me'

param azureOpenAIEmbeddingModel = 'text-embedding-3-large'
param embeddingMaxTokens = 8191
param embeddingModelVersion = '1'

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




