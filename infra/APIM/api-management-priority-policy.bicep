
param apiManagementName string
param openAiApiName string
param policyXml string
@allowed([
  'rawxml'
  'rawxml-link'
  'xml'
  'xml-link'
])
param format string

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' existing= {
  name: apiManagementName
}

resource openAiApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' existing = {
  parent: apiManagement
  name: openAiApiName
}

resource openaiApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' =  {
  name: 'policy'
  parent: openAiApi
  properties: {
    value: policyXml
    format: format
  }
}
