targetScope = 'subscription'

param appName string
param location string

var abbrs = loadJsonContent('./constants/abbreviations.json')
var resourceGroupName = '${abbrs.resourceGroup}${appName}-${location}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
}

module names 'resourcenames.bicep' = {
  name: 'names'
  params: {
    location: location
    appName: appName
  }
 
}

module containerRegistry 'core/container-registry.bicep' = {
  name: 'ContainerRegistry-${appName}'
  scope: rg
  params: {
    location: location
    containerRegistryName: names.outputs.containerRegistryName
  }

}

module managedIdentity 'core/managed-identity.bicep' = {
  name: 'ManagedIdentity-${appName}'
  scope: rg
  params: {
    location: location
    name: names.outputs.managedIdentityName
  }
}

module acrRoleAssignments 'core/roleassignments-acrpull.bicep' =  {
  name: 'AcrRoleAssignments-${appName}'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalIds: [managedIdentity.outputs.principalId]
  }
}

output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
