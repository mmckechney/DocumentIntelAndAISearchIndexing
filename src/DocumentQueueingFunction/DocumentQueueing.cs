using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.CompilerServices;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.DocumentQueueingFunction
{
   public class DocumentQueueing
   {
      private readonly ILogger<DocumentQueueing> logger;
      private readonly Tracker<DocumentQueueing> tracker;
      private readonly StorageHelper storageHelper;
      private readonly ServiceBusHelper serviceBusHelper;
      private readonly Settings settings;

      public DocumentQueueing(ILogger<DocumentQueueing> logger, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, Settings settings, Tracker<DocumentQueueing> tracker)
      {
         this.logger = logger;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
         this.settings = settings;
         this.tracker = tracker;
      }

      public async Task<int> QueueDocumentsAsync(bool force, DateTime? queuedDate, CancellationToken cancellationToken)
      {
         try
         {
            logger.LogInformation("Request received to queue documents");
            logger.LogInformation("Processing settings: Force re-queue: '{Force}', Re-queue document previously queued before: '{QueuedDate}'", force, queuedDate);

            var containerClient = storageHelper.GetContainerClient(settings.SourceContainerName);
            logger.LogInformation("Using storage container '{ContainerName}' as files source.", containerClient.Name);

            var blobList = containerClient.GetBlobsAsync(new GetBlobsOptions { Traits = BlobTraits.Metadata });
            var metadataTasks = new List<Task>();
            int counter = 0;
            int fileCounter = 0;

            await foreach (var blob in blobList.WithCancellation(cancellationToken))
            {
               cancellationToken.ThrowIfCancellationRequested();

               if (!force && blob.Metadata.ContainsKey("Processed"))
               {
                  logger.LogInformation("Skipping {BlobName}. Already marked as Processed and 'force' flag not set", blob.Name);
                  continue;
               }

               if (queuedDate.HasValue && ShouldSkipBasedOnQueueDate(blob.Metadata, queuedDate.Value))
               {
                  logger.LogInformation("Skipping {BlobName}. Already marked as queued with metadata date newer than target {QueuedDate}", blob.Name, queuedDate);
                  continue;
               }

               if (counter > 9)
               {
                  counter = 0;
               }

               logger.LogDebug("Found file {BlobName}", blob.Name);

               var fileMsg = new FileQueueMessage() { SourceFileName = blob.Name, ContainerName = containerClient.Name, RecognizerIndex = counter };
               fileMsg = await tracker.TrackAndUpdate(fileMsg, $"Sending to {settings.DocumentQueueName}");
               var sbMessage = fileMsg.AsMessage();
               await serviceBusHelper.SendMessageAsync(settings.DocumentQueueName, sbMessage);

               fileMsg = await tracker.TrackAndUpdate(fileMsg, $"Sent to {settings.DocumentQueueName}");
               logger.LogInformation("Queued file {BlobName} for processing from storage container '{ContainerName}'", blob.Name, containerClient.Name);
               fileCounter++;
               counter++;

               metadataTasks.Add(UpdateBlobMetaDataAsync(blob.Name, containerClient, "IsQueued", DateTime.UtcNow.ToString(), cancellationToken));

               if (metadataTasks.Count > 200)
               {
                  logger.LogInformation("Purging collection of completed tasks....");
                  await Task.WhenAll(metadataTasks);
                  metadataTasks.Clear();
               }
            }

            if (metadataTasks.Count > 0)
            {
               logger.LogInformation("Waiting for metadata updates to complete....");
               await Task.WhenAll(metadataTasks);
            }

            return fileCounter;
         }
         catch (Exception ex)
         {
            logger.LogError(ex, "Failed to queue files");
            throw;
         }
      }

      private static bool ShouldSkipBasedOnQueueDate(IDictionary<string, string> metadata, DateTime queuedDate)
      {
         if (!metadata.TryGetValue("IsQueued", out var queueDateStr))
         {
            return false;
         }

         if (!DateTime.TryParse(queueDateStr, out var fileQueueDate))
         {
            return false;
         }

         return fileQueueDate > queuedDate;
      }

      private async Task UpdateBlobMetaDataAsync(string blobName, BlobContainerClient containerClient, string key, string value, CancellationToken cancellationToken, int retry = 0)
      {
         try
         {
            logger.LogDebug("Updating metadata ({Key}={Value}) on blob {BlobName}", key, value, blobName);
            var meta = new Dictionary<string, string>
            {
               { key, value }
            };
            var bc = containerClient.GetBlobClient(blobName);
            await bc.SetMetadataAsync(meta, cancellationToken: cancellationToken);
            logger.LogInformation("Updated metadata ({Key}={Value}) on blob {BlobName}", key, value, blobName);
         }
         catch (Exception ex)
         {
            logger.LogError(ex, "Error updating Blob Metadata for file '{BlobName}'", blobName);
            if (retry < 3)
            {
               var attempt = retry + 1;
               logger.LogWarning("Retrying to set Blob Metadata for file '{BlobName}'. Attempt #{Attempt}", blobName, attempt);
               await UpdateBlobMetaDataAsync(blobName, containerClient, key, value, cancellationToken, attempt);
            }
            else
            {
               logger.LogError("Error updating Blob Metadata for file '{BlobName}'. Retries exceeded.", blobName);
            }
         }
      }
   }
}
