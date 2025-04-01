@description('The name of the Cosmos DB account')
param cosmosDbAccountName string

@description('The location of the Cosmos DB account')
param location string = resourceGroup().location

@description('The name of the database to create')
param databaseName string
param cosmosContainerName string

@description('The name of the Key Vault')
param keyVaultName string

@description('The name of the Virtual Network')
param vnetName string

@description('The name of the subnet for the service endpoint')
param subnetName string

param myPublicIp string = ''
param functionSubnetId string
param apimSubnetId string

var keyVaultKeys = loadJsonContent('../constants/keyVaultKeys.json')

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    publicNetworkAccess: 'Enabled' // Enable public access for VNet Service Endpoints
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: [
      {
        id: subnet.id
        ignoreMissingVNetServiceEndpoint: false
      }
      {
        id: functionSubnetId
        ignoreMissingVNetServiceEndpoint: false
      }
      {
        id: apimSubnetId
        ignoreMissingVNetServiceEndpoint: false
      }
    ]
    ipRules: !empty(myPublicIp) ? [
      {
        ipAddressOrRange: myPublicIp
      }
    ] : []
    enableFreeTier: false
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-10-15' = {
  parent: cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-10-15' = {
  parent: cosmosDbDatabase
  name: cosmosContainerName
  properties: {
    resource: {
      id: cosmosContainerName
      partitionKey: {
        paths: ['/id'] // Define the partition key path
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

resource adminKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: keyVaultKeys.COSMOS_CONNECTION
  properties: {
    value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output cosmosDbAccountName string = cosmosDbAccount.name
output cosmosDbDatabaseName string = cosmosDbDatabase.name
