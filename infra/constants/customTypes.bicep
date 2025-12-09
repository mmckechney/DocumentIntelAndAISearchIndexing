
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
  name: 'BasicV2' | 'StandardV2' | 'PremiumV2'
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
  serviceName: string?
}

@export()
type openApiApimBackends = {
  name: string
  id: string
  priority: int?
}

