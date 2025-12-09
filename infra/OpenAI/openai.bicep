import * as customTypes from '../constants/customTypes.bicep'

param instancePrefix string
param openAIInstances customTypes.openAIConfigs
param managedIdentityId string



module openAI 'openai-instance.bicep' = [ for openAIInstance in openAIInstances.configs: {
  name: !empty(openAIInstance.?name) ? openAIInstance.name! : '${instancePrefix}${openAIInstance.suffix}'
  params: {
    managedIdentityId: managedIdentityId
    name: !empty(openAIInstance.?name) ? openAIInstance.name! : '${instancePrefix}${openAIInstance.suffix}'
    location: openAIInstance.location
    openAiConfig : openAIInstance
    completionModel: openAIInstances.completionModel
    embeddingModel: openAIInstances.embeddingModel
  }
 
}]

//add the priority to the output
output openAIDeployments customTypes.openAiDeploymentInfo[] = [for i in range(0, length(openAIInstances.configs)): {
  id: openAI[i].outputs.openAiInfo.id
  name: openAI[i].outputs.openAiInfo.name
  host: 'https://${openAI[i].outputs.openAiInfo.name}.openai.azure.com/'
  endpoint: 'https://${openAI[i].outputs.openAiInfo.name}.openai.azure.com/openai/deployments/${openAI[i].outputs.openAiInfo.name}/chat/completions?api-version=2023-10-01-preview'
  priority: openAIInstances.configs[i].priority
}]
