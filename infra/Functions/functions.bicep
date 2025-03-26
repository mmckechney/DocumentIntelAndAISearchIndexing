param funcAppPlan string
param location string = resourceGroup().location
param processFunctionName string
param aiSearchIndexFunctionName string
param customFieldFunctionName string
param functionSubnetId string
param functionStorageAcctName string
param keyVaultUri string
param processedQueueName string
param serviceBusNs string
param formStorageAcctName string
param moveFunctionName string
param queueFunctionName string
param customFieldQueueName string
param docQueueName string
param toIndexQueueName string
param openAiEmbeddingModel string
param aiSearchEndpoint string
param openAiEndpoint string
param azureOpenAiEmbeddingMaxTokens int = 8091
param managedIdentityId string
param documentStorageContainer string
param processResultsContainer string
param completedContainer string
param appInsightsName string
param includeGeneralIndex bool = true
param openAiChatModel string
param askQuestionsFunctionName string


resource appInsights 'Microsoft.Insights/components@2020-02-02'existing = {
  name: appInsightsName
}

module functionAppPlan 'appplan.bicep' = {
  name: funcAppPlan
  params: {
    location: location
    funcAppPlan: funcAppPlan
  }
}

module processFunction 'function-process.bicep' = {
  name: processFunctionName
  params: {
    location: location
    processFunctionName: processFunctionName
    functionSubnetId: functionSubnetId
    functionStorageAcctName: functionStorageAcctName
    keyVaultUri: keyVaultUri
    processedQueueName: processedQueueName
    serviceBusNs: serviceBusNs
    formStorageAcctName: formStorageAcctName
    documentStorageContainer: documentStorageContainer
    processResultsContainer: processResultsContainer
    completedContainer: completedContainer
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    customFieldQueueName: customFieldQueueName
    docQueueName: docQueueName
  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}


module customFieldFunction 'function-customfield.bicep' = {
  name: processFunctionName
  params: {
    location: location
    customFieldFunctionName: customFieldFunctionName
    functionSubnetId: functionSubnetId
    functionStorageAcctName: functionStorageAcctName
    keyVaultUri: keyVaultUri
    customFieldQueueName: customFieldQueueName
    serviceBusNs: serviceBusNs
    formStorageAcctName: formStorageAcctName
    documentStorageContainer: documentStorageContainer
    processResultsContainer: processResultsContainer
    completedContainer: completedContainer
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    toIndexQueueName: toIndexQueueName
  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}

module aiSearchFunction 'function-aisearch.bicep' = {
  name: aiSearchIndexFunctionName
  params: {
    location: location
    aiSearchIndexFunctionName: aiSearchIndexFunctionName
    keyVaultUri: keyVaultUri
    openAiEmbeddingModel: openAiEmbeddingModel
    aiSearchEndpoint: aiSearchEndpoint
    openAiEndpoint: openAiEndpoint
    azureOpenAiEmbeddingMaxTokens: azureOpenAiEmbeddingMaxTokens
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    formStorageAcctName: formStorageAcctName
    functionStorageAcctName: functionStorageAcctName
    functionSubnetId: functionSubnetId
    processResultsContainer: processResultsContainer
    serviceBusNs: serviceBusNs
    toIndexQueueName: toIndexQueueName
    includeGeneralIndex: includeGeneralIndex
    openAiChatModel: openAiChatModel

  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}

module moveFunction 'function-move.bicep' = {
  name: moveFunctionName
  params: {
    location: location
    moveFunctionName: moveFunctionName
    keyVaultUri: keyVaultUri
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    formStorageAcctName: formStorageAcctName
    functionStorageAcctName: functionStorageAcctName
    functionSubnetId: functionSubnetId
    processResultsContainer: processResultsContainer
    completedContainer: completedContainer
    documentStorageContainer: documentStorageContainer
    processedQueueName: processedQueueName
  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}

module queueFunction 'functions-queueing.bicep' = {
  name: queueFunctionName
  params: {
    location: location
    queueFunctionName: queueFunctionName
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    formStorageAcctName: formStorageAcctName
    functionStorageAcctName: functionStorageAcctName
    functionSubnetId: functionSubnetId
    documentStorageContainer: documentStorageContainer
    docQueueName: docQueueName
    serviceBusNs: serviceBusNs
  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}

module askQuestions 'function-askquestions.bicep' = {
  name: askQuestionsFunctionName
  params: {
    location: location
    askQuestionsFunctionName: askQuestionsFunctionName
    keyVaultUri: keyVaultUri
    openAiEmbeddingModel: openAiEmbeddingModel
    aiSearchEndpoint: aiSearchEndpoint
    openAiEndpoint: openAiEndpoint
    azureOpenAiEmbeddingMaxTokens: azureOpenAiEmbeddingMaxTokens
    managedIdentityId: managedIdentityId
    appInsightsName: appInsightsName
    funcAppPlan: funcAppPlan
    functionStorageAcctName: functionStorageAcctName
    functionSubnetId: functionSubnetId
    openAiChatModel: openAiChatModel

  }
  dependsOn: [
    functionAppPlan
    appInsights
  ]
}

output systemAssignedIdentities array = [
  processFunction.outputs.systemAssignedIdentity
  aiSearchFunction.outputs.systemAssignedIdentity
  moveFunction.outputs.systemAssignedIdentity
  queueFunction.outputs.systemAssignedIdentity
  askQuestions.outputs.systemAssignedIdentity

  
]
