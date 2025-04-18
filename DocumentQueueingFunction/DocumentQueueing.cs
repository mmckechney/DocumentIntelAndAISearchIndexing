using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
namespace HighVolumeProcessing.DocumentQueueingFunction
{
   public class DocumentQueueing
   {
      private readonly ILogger<DocumentQueueing> logger;
      Tracker<DocumentQueueing> tracker;
      private StorageHelper storageHelper;
      private ServiceBusHelper serviceBusHelper;
      private Settings settings;
      public DocumentQueueing(ILogger<DocumentQueueing> logger, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, Settings settings, Tracker<DocumentQueueing> tracker)
      {
         this.logger = logger;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
         this.settings = settings;
         this.tracker = tracker;
      }

      public async Task<(string, HttpStatusCode)> QueueDocs(bool force, DateTime fromDate)
      {
         int fileCounter = 0;
         logger.LogInformation("Request received to queue documents");
         var cancelSource = new CancellationTokenSource();

         logger.LogInformation($"Processing settings: Force re-queue: '{force.ToString()}',  Re-queue document previously queued before: '{fromDate}'");
         List<Task> metaDataTasks = new List<Task>();

         try
         {
            BlobContainerClient containerClient;

            containerClient = storageHelper.GetContainerClient(settings.SourceContainerName);
            logger.LogInformation($"Using storage container '{containerClient.Name}' as files source.");

            var blobList = containerClient.GetBlobsAsync(BlobTraits.Metadata);
            int counter = 0;
            await foreach (var blob in blobList)
            {
               if (cancelSource.IsCancellationRequested)
               {
                  break;
               }

               if (!force && blob.Metadata.ContainsKey("Processed"))
               {
                  logger.LogInformation($"Skipping {blob.Name}. Already marked as Processed and 'force' flag not set");
                  continue;
               }

               string queueDateStr;
               if (blob.Metadata.TryGetValue("IsQueued", out queueDateStr) && fromDate != DateTime.MinValue)
               {
                  DateTime fileQueueDate;
                  if (DateTime.TryParse(queueDateStr, out fileQueueDate))
                  {
                     if (fileQueueDate > fromDate)
                     {
                        logger.LogInformation($"Skipping {blob.Name}. Already marked as queued and metadata date of {fileQueueDate} is greater than target requeue date of {fromDate}");
                        continue;
                     }
                  }
               }

               if (counter > 9) counter = 0;
               logger.LogDebug($"Found file  {blob.Name}");

               var fileMsg = new FileQueueMessage() { SourceFileName = blob.Name, ContainerName = containerClient.Name, RecognizerIndex = counter };
               fileMsg = await tracker.TrackAndUpdate(fileMsg, $"Sending to {settings.DocumentQueueName}");
               var sbMessage = fileMsg.AsMessage();
               await serviceBusHelper.SendMessageAsync(settings.DocumentQueueName, sbMessage);

               fileMsg = await tracker.TrackAndUpdate(fileMsg, $"Sent to {settings.DocumentQueueName}");
               logger.LogInformation($"Queued file {blob.Name} for processing from storage container '{containerClient.Name}' ");
               fileCounter++;
               counter++;

               metaDataTasks.Add(UpdateBlobMetaData(blob.Name, containerClient, "IsQueued", DateTime.UtcNow.ToString()));

               if (metaDataTasks.Count > 200)
               {
                  logger.LogInformation("Purging collection of completed tasks....");
                  var waiting = Task.WhenAll(metaDataTasks);
                  await waiting;
                  metaDataTasks.Clear();
               }
            }

            if (metaDataTasks.Count > 0)
            {
               logger.LogInformation("Waiting for metadata updates to complete....");
               var waiting = Task.WhenAll(metaDataTasks);
               await waiting;
            }
            return ($"Queued {fileCounter} files", System.Net.HttpStatusCode.OK);
         }
         catch (Exception exe)
         {
            return ($"Failed to queue files: {exe.ToString()}", System.Net.HttpStatusCode.BadRequest);
         }
      }
      public async Task UpdateBlobMetaData(string blobName, BlobContainerClient containerClient, string key, string value, int retry = 0)
      {
         try
         {

            BlobClientOptions opts = new BlobClientOptions();

            logger.LogDebug($"Updating metadata ({key}={value}) on blob {blobName} ");
            var meta = new Dictionary<string, string>();
            meta.Add(key, value);
            var bc = containerClient.GetBlobClient(blobName);
            await bc.SetMetadataAsync(meta);
            logger.LogInformation($"Updated metadata ({key}={value}) on blob {blobName} ");
         }
         catch (Exception ex)
         {
            logger.LogError($"Error updating Blob Metadata for file '{blobName}'. {ex.Message}");
            if (retry < 3)
            {
               retry = retry + 1;
               logger.LogError($"Retrying to set Blob Metadata for file '{blobName}'. Attempt #{retry}");
               await UpdateBlobMetaData(blobName, containerClient, key, value, retry);
            }
            else
            {
               logger.LogError($"Error updating Blob Metadata for file '{blobName}'. Retries exceeded. {ex.Message}");
            }
         }
      }

   }
}
