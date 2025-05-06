param funcAppPlan string
param location string = resourceGroup().location
param funcAppPlanSku string
resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: funcAppPlan
  location: location
  sku: {
    name: funcAppPlanSku
    capacity: 4 
  }
  properties: {
    reserved: false 
  }
}

output functionAppPlanId string = functionAppPlan.id
