
@export()
type openAIConfigs = {
  embeddingModel: string
  completionModel: string
  embeddingMaxTokens: int
  configs: openAIConfig[] 
}

@export()
type openAIConfig = {
  name: string
  location: string
  suffix: string
  priority: int
  embedding: {
    capacity: int
  }
  completion: {
    capacity: int
    sku: 'Standard' | 'GlobalStandard'
  }
}

@export()
type apimSkuInfo = {
  name: 'Developer' | 'Standard' | 'Premium' | 'Basic' | 'Consumption' | 'Isolated'
  capacity: int
}

@export()
type roleAssignmentInfo = {
  roleDefinitionId: string
  principalId: string
}

@export()
type keyVaultSecretsInfo = {
  keyVaultName: string
  primaryKeySecretName: string
}


@export()
type openAiDeploymentInfo = {
  id: string
  name: string
  host: string
  endpoint: string
  priority: int?

}

@export()
type functionValue = {
  name: string
  tag: string
}

