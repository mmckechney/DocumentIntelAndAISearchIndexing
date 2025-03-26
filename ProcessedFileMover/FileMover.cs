using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs.Models;
using AzureUtilities;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace ProcessedFileMover
{
   public class FileMover
   {
      private readonly ILogger<FileMover> logger;
      private StorageHelper storageHelper;

      public FileMover(ILogger<FileMover> logger, StorageHelper storageHelper)
      {
         this.logger = logger;
         this.storageHelper = storageHelper;
      }

      [Function("FileMover")]
      public async Task Run([ServiceBusTrigger("%SERVICE_BUS_PROCESSED_QUEUE_NAME%", Connection = "SERVICE_BUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         var filemessage = message.As<FileQueueMessage>();
         logger.LogInformation($"Moving processed file {filemessage.FileName} to {Settings.ProcessResultsContainerName} container");
         bool success = await MoveOriginalFileToProcessed(filemessage.FileName);
         if (success)
         {
            logger.LogInformation($"Successfully move file {filemessage.FileName} to {Settings.ProcessResultsContainerName} container");
         }
         else
         {
            logger.LogInformation($"Failed move file {filemessage.FileName} to {Settings.ProcessResultsContainerName} container");
         }

      }

      public async Task<bool> MoveOriginalFileToProcessed(string sourceFileName)
      {
         try
         {
            var sourceBlob = storageHelper.GetBlobClient(Settings.SourceContainerName, sourceFileName); 
            var destBlob = storageHelper.GetBlobClient(Settings.CompletedContainerName, sourceFileName); 

            var operation = await destBlob.StartCopyFromUriAsync(sourceBlob.Uri);
            operation.WaitForCompletion();
            if (operation.GetRawResponse().Status >= 300)
            {
               return false;
            }
            bool deleteResp = await sourceBlob.DeleteIfExistsAsync();
            return deleteResp;
         }
         catch (Exception exe)
         {
            logger.LogError(exe.ToString());
            return false;
         }
      }

      public async Task<bool> CleanupFolder()
      {
         List<string> lstBlobsToMove = new List<string>();
        
         var blobList = storageHelper.GetContainerClient(Settings.SourceContainerName).GetBlobsAsync(BlobTraits.Metadata);
         await foreach (var blob in blobList)
         {
            if (blob.Metadata.ContainsKey("Processed"))
            {
               lstBlobsToMove.Add(blob.Name);
            }
         }
         if (lstBlobsToMove.Count == 0)
         {
            return true;
         }

         await Parallel.ForEachAsync(lstBlobsToMove,
             new ParallelOptions() { MaxDegreeOfParallelism = 20 },
             async (blobName, cancelationToken) =>
             {
                bool success = await MoveOriginalFileToProcessed(blobName);
                if (success)
                {
                   logger.LogInformation($"Successfully moved file '{blobName}'");
                }
                else
                {
                   logger.LogInformation($"File '{blobName}' was not moved!");
                }
             });

         return true;
      }
   }
}
