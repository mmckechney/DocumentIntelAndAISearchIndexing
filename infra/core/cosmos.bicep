param resource_location string 
param databaseAccounts_getorganized_acct_name string 

//Cosmos Resources
resource cosmosGremlinAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: databaseAccounts_getorganized_acct_name
  location: resource_location
  tags: {
    defaultExperience: 'Gremlin (graph)'
    'hidden-cosmos-mmspecial': ''
  }
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'None'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
   
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: resource_location
      }
    ]
    capabilities: [
      {
        name: 'EnableGremlin'
      }
      {
        name: 'EnableServerless'
      }
    ]
    ipRules: [
      {
        ipAddressOrRange: '52.226.97.243'
      }
      {
        ipAddressOrRange: '52.226.98.174'
      }
      {
        ipAddressOrRange: '52.226.98.238'
      }
      {
        ipAddressOrRange: '52.149.189.29'
      }
      {
        ipAddressOrRange: '52.226.99.134'
      }
      {
        ipAddressOrRange: '52.226.99.209'
      }
      {
        ipAddressOrRange: '52.226.99.242'
      }
      {
        ipAddressOrRange: '52.191.99.38'
      }
      {
        ipAddressOrRange: '52.226.100.78'
      }
      {
        ipAddressOrRange: '52.226.100.110'
      }
      {
        ipAddressOrRange: '52.226.100.182'
      }
      {
        ipAddressOrRange: '52.226.101.48'
      }
      {
        ipAddressOrRange: '52.226.101.73'
      }
      {
        ipAddressOrRange: '52.226.101.85'
      }
      {
        ipAddressOrRange: '52.226.101.228'
      }
      {
        ipAddressOrRange: '52.226.102.12'
      }
      {
        ipAddressOrRange: '52.226.102.146'
      }
      {
        ipAddressOrRange: '52.151.243.222'
      }
      {
        ipAddressOrRange: '52.226.103.13'
      }
      {
        ipAddressOrRange: '52.226.103.16'
      }
      {
        ipAddressOrRange: '52.226.103.215'
      }
      {
        ipAddressOrRange: '52.224.133.159'
      }
      {
        ipAddressOrRange: '52.249.240.7'
      }
      {
        ipAddressOrRange: '52.249.241.81'
      }
      {
        ipAddressOrRange: '52.249.241.150'
      }
      {
        ipAddressOrRange: '52.249.241.156'
      }
      {
        ipAddressOrRange: '52.249.241.206'
      }
      {
        ipAddressOrRange: '52.188.94.243'
      }
      {
        ipAddressOrRange: '52.249.241.252'
      }
      {
        ipAddressOrRange: '52.249.242.105'
      }
      {
        ipAddressOrRange: '20.49.104.46'
      }
      {
        ipAddressOrRange: '8.9.81.236'
      }
        
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
   }
}
resource getOrganizedDatabase 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2022-08-15' = {
  parent: cosmosGremlinAccount
  name: 'GetOrganized-Db'
  properties: {
    resource: {
      id: 'GetOrganized-Db'
    }
  }
}
resource getOrganizedGraph 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/graphs@2022-08-15' = {
  parent: getOrganizedDatabase
  name: 'GetOrganized-graph'
  properties: {
    resource: {
      id: 'GetOrganized-graph'
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
      partitionKey: {
        paths: [
          '/name'
        ]
        kind: 'Hash'
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}

output cosmosResourceId string = cosmosGremlinAccount.id
output cosmosApiVersion string = cosmosGremlinAccount.apiVersion
