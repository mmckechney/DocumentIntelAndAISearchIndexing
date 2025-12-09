using Azure.Storage.Blobs.Models;
using HighVolumeProcessing.UtilityLibrary;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.ProcessedFileMover
{
   public class FileMover
   {
      private readonly ILogger<FileMover> log;
      private StorageHelper storageHelper;
      private Settings settings;
      private Tracker<FileMover> tracker;
      public FileMover(ILogger<FileMover> logger, StorageHelper storageHelper, Settings settings, Tracker<FileMover> tracker)
      {
         this.log = logger;
         this.storageHelper = storageHelper;
         this.settings = settings;
         this.tracker = tracker;
      }

      public async Task ProcessMessageAsync(FileQueueMessage fileMessage)
      {
         ArgumentNullException.ThrowIfNull(fileMessage);
         try
         {
            log.LogInformation("FileMover triggered with message -- {Message}", fileMessage);

            await tracker.TrackAndUpdate(fileMessage, "Moving original file");
            bool success = await MoveOriginalFileToCompleted(fileMessage.SourceFileName);
            if (success)
            {
               log.LogInformation("Successfully moved file {FileName} to {Container}", fileMessage.SourceFileName, settings.CompletedContainerName);
               await tracker.TrackAndUpdate(fileMessage, "Successfully moved original file");
            }
            else
            {
               log.LogWarning("Failed move file {FileName} to {Container}", fileMessage.SourceFileName, settings.CompletedContainerName);
               await tracker.TrackAndUpdate(fileMessage, "Failed to move original file");
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe, "FileMover failure for {FileName}", fileMessage.SourceFileName);
            await tracker.TrackAndUpdate(fileMessage, $"Failure in FileMover: {exe.Message}");
            throw;
         }
      }

      public async Task<bool> MoveOriginalFileToCompleted(string sourceFileName)
      {
         try
         {
            var sourceBlob = storageHelper.GetBlobClient(settings.SourceContainerName, sourceFileName);
            var destBlob = storageHelper.GetBlobClient(settings.CompletedContainerName, sourceFileName);

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
            log.LogError(exe.ToString());
            return false;
         }
      }

      public async Task<bool> CleanupFolder()
      {
         List<string> lstBlobsToMove = new List<string>();

         var blobList = storageHelper.GetContainerClient(settings.SourceContainerName).GetBlobsAsync(BlobTraits.Metadata);
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
                bool success = await MoveOriginalFileToCompleted(blobName);
                if (success)
                {
                   log.LogInformation($"Successfully moved file '{blobName}'");
                }
                else
                {
                   log.LogInformation($"File '{blobName}' was not moved!");
                }
             });

         return true;
      }
   }
}
