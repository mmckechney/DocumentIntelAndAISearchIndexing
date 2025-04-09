param funcAppPlan string
param funcAppPlanSku string
param location string = resourceGroup().location

resource functionAppPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: funcAppPlan
  location: location
  sku: {
    name: funcAppPlanSku
   }
  properties: {
    reserved: true 
  }
}
