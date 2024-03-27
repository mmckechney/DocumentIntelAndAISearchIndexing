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

      public FileMover(ILogger<FileMover> logger)
      {
         this.logger = logger;
      }

      [Function("FileMover")]
      public async Task Run([ServiceBusTrigger("processedqueue", Connection = "SERVICE_BUS_CONNECTION")] ServiceBusReceivedMessage message)
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
            var sourceBlob = Settings.SourceContainerClient.GetBlobClient(sourceFileName);
            var destBlob = Settings.CompletedContainerClient.GetBlobClient(sourceFileName);

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
         var blobList = Settings.SourceContainerClient.GetBlobsAsync(BlobTraits.Metadata);
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
