using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using hpM = HighVolumeProcessing.UtilityLibrary.Models;
namespace HighVolumeProcessing.UtilityLibrary
{
   public class CosmosDbHelper
   {
      private ILogger<CosmosDbHelper> log;
      private IConfiguration config;
      private Settings settings;
      private CosmosClient? _client;
      private Container? _container;
      public CosmosDbHelper(ILogger<CosmosDbHelper> log, IConfiguration config, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.settings = settings;
      }

      
      
      public CosmosClient Client
      {
         get
         {
            if (_client == null)
            {
               var connectionString = settings.CosmosDbConnectionString;
               _client = new CosmosClient(connectionString);
            }
            return _client;
         }
      }

      

      public Container CosmosContainer
      {
         get
         {
            if (_container == null)
            {
               try
               {
                  var database = Client.CreateDatabaseIfNotExistsAsync(settings.CosmosDbName).GetAwaiter().GetResult();
                  var container = database.Database.CreateContainerIfNotExistsAsync(settings.CosmosConstainerName, "/id").GetAwaiter().GetResult();
                  _container = container;
               }
               catch (Exception ex)
               {
                  log.LogError(ex, "Error creating Cosmos DB container");
                  throw;
               }
            }
            return _container;
         }
      }


      public async Task<ItemResponse<hpM.FileQueueMessage>> UpsertItemAsync(string databaseName, string containerName, hpM.FileQueueMessage item)
      {
         try
         {
            if(item.Id == null)
            {
               item.Id = Guid.NewGuid().ToString();
            }
            var response = await CosmosContainer.UpsertItemAsync(item);
            return response;
         }
         catch (Exception ex)
         {
            log.LogError(ex, "Error creating item in Cosmos DB");
            throw;
         }
      }
   }
}
