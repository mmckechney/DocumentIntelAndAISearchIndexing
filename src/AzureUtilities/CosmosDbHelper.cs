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
      private Database? _database;
      public CosmosDbHelper(ILogger<CosmosDbHelper> log, IConfiguration config, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.settings = settings;
      }

      
      
      internal CosmosClient Client
      {
         get
         {
            if (_client == null)
            {
               try
               {
                  var accountEndpoint = settings.CosmosAccountEndpoint ?? throw new InvalidOperationException($"Missing {ConfigKeys.COSMOS_ACCOUNT_ENDPOINT} in configuration.");
                  _client = new CosmosClient(accountEndpoint, AadHelper.TokenCredential);
               }
               catch(Exception ex)
               {
                  log.LogError($"Issue creating CosmosClient: {ex.Message}");
               }
            }
            return _client;
         }
      }

      
      internal Database Database
      {
         get
         {
            if (_database == null)
            {
               try
               {
                  //_database = Client.CreateDatabaseIfNotExistsAsync(settings.CosmosDbName).GetAwaiter().GetResult();
                  _database = Client.GetDatabase(settings.CosmosDbName);
               }
               catch (Exception ex)
               {
                  log.LogError($"Issue creating Cosmos Database: {ex.Message}");
               }
            }
            return _database;
         }
      }



      internal Container CosmosContainer
      {
         get
         {
            if (_container == null)
            {
               try
               {
                  
                  //var container = Database.CreateContainerIfNotExistsAsync(settings.CosmosConstainerName, "/id").GetAwaiter().GetResult();
                  var container = Database.GetContainer(settings.CosmosConstainerName);
                  _container = container;
               }
               catch (Exception ex)
               {
                  log.LogError($"Issue creating Cosmos Container: {ex.Message}");
                  throw;
               }
            }
            return _container;
         }
      }


      internal async Task<hpM.FileQueueMessage> UpsertRecord(hpM.FileQueueMessage item)
      {
         try
         {
            if (string.IsNullOrWhiteSpace(item.id))
            {
               item.id = Guid.NewGuid().ToString();
               var response = await CosmosContainer.UpsertItemAsync(item);
               return response.Resource;
            }
            else
            {
               var retrieved = await GetTrackingRecord(item);
               retrieved.UpdateFromMessage(item);
               var response = await CosmosContainer.UpsertItemAsync(retrieved);
               return response.Resource;
            }

         }
         catch (Exception ex)
         {
            log.LogError($"Error upserting tracking record for {item.ToString()}. [{ex.Message}]");
            return item; ;
         }
      }


      internal async Task<hpM.FileQueueMessage> GetTrackingRecord(hpM.FileQueueMessage item)
      {
         try
         {
            //retrieve item from cosmos

            if(item.id == null) {
               item.id = Guid.NewGuid().ToString();
            }
            var response = await CosmosContainer.ReadItemAsync<hpM.FileQueueMessage>(item.id, new PartitionKey(item.id));
            return response.Resource;
         
         }
         catch (Exception ex)
         {
            log.LogError($"Error retrieving Tracking information for {item.ToString()}. ({ex.Message})");
            return item;
         }
      }
   }
}
