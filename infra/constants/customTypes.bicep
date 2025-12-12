
@export()
type foundryModelConfig = {
  name: string
  version: string
  sku: string
  capacity: int
}

@export()
type foundryConfig = {
  projectDisplayName: string
  embeddingMaxTokens: int
  chatModel: foundryModelConfig
  embeddingModel: foundryModelConfig
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
type functionValue = {
  name: string
  tag: string
  serviceName: string?
}

