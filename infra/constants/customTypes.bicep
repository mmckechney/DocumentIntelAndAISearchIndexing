
@export()
type openAIConfig = {
  name: string?
  location: string
  suffix: string
  priority: int
}

@export()
type skuInfo = {
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

