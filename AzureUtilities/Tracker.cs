using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HighVolumeProcessing.UtilityLibrary
{
   public class Tracker<T>
   {
      private ILogger<Tracker<T>> log;
      private IConfiguration config;
      private Settings settings;
      private CosmosDbHelper cosmosDbHelper;
      private string typeName;
      public Tracker(ILogger<Tracker<T>> log, IConfiguration config, Settings settings, CosmosDbHelper cosmosDbHelper) 
      {
         this.log = log;
         this.config = config;
         this.settings = settings;
         this.cosmosDbHelper = cosmosDbHelper;
         this.typeName = typeof(T).Name;
      }

      public async Task<FileQueueMessage> TrackAndUpdate(FileQueueMessage fileQueueMessage, string trackingMessage)
      {
         fileQueueMessage.Tracking.Add(new(this.typeName, trackingMessage, DateTime.UtcNow));
         var item = await cosmosDbHelper.UpsertRecord(fileQueueMessage);
         return item;
      }
    

   }
}
