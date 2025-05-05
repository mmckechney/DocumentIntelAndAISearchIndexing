import * as customTypes from '../constants/customTypes.bicep'

param azureOpenAIChatModel string
param azureOpenAIEmbeddingModel string
param instancePrefix string
param openAIInstances customTypes.openAIConfig[]
param keyvaultName string
param managedIdentityId string

var deployments = [
  {
    name:  azureOpenAIChatModel
    model: {
      format: 'OpenAI'
      name: azureOpenAIChatModel
    }
    sku: {
      name: 'Standard'
      capacity: 49
    }
  }
  {
    name: azureOpenAIEmbeddingModel
    model: {
      format: 'OpenAI'
      name: azureOpenAIEmbeddingModel
    }
    sku: {
      name: 'Standard'
      capacity: 100
    }
  }
]


module openAI 'openai-instance.bicep' = [ for openAIInstance in openAIInstances: {
  name: !empty(openAIInstance.?name) ? openAIInstance.name! : '${instancePrefix}${openAIInstance.suffix}'
  params: {
    managedIdentityId: managedIdentityId
    name: !empty(openAIInstance.?name) ? openAIInstance.name! : '${instancePrefix}${openAIInstance.suffix}'
    location: openAIInstance.location
    deployments: deployments
    keyVaultConfig: {
      keyVaultName: keyvaultName
      primaryKeySecretName: 'OPENAI-API-KEY-${toUpper(openAIInstance.?name)}'
    }
  }
 
}]

//add the priority to the output
output openAIDeployments customTypes.openAiDeploymentInfo[] = [for i in range(0, length(openAIInstances)): {
  id: openAI[i].outputs.openAiInfo.id
  name: openAI[i].outputs.openAiInfo.name
  host: 'https://${openAI[i].outputs.openAiInfo.name}.openai.azure.com/'
  endpoint: 'https://${openAI[i].outputs.openAiInfo.name}.openai.azure.com/openai/deployments/${openAI[i].outputs.openAiInfo.name}/chat/completions?api-version=2023-10-01-preview'
  priority: openAIInstances[i].priority
}]
