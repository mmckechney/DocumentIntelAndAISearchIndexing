using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs.Models;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace HighVolumeProcessing.ProcessedFileMover
{
   public class FileMover : BackgroundService
   {
      private readonly ILogger<FileMover> log;
      private StorageHelper storageHelper;
      private Settings settings;
      private Tracker<FileMover> tracker;
      private IConfiguration config;
      private ServiceBusHelper serviceBusHelper;
      public FileMover(ILogger<FileMover> logger, IConfiguration config, StorageHelper storageHelper, Settings settings, ServiceBusHelper serviceBusHelper, Tracker<FileMover> tracker)
      {
         this.log = logger;
         this.storageHelper = storageHelper;
         this.settings = settings;
         this.tracker = tracker;
         this.serviceBusHelper = serviceBusHelper;
         this.config = config;
      }

      protected async override Task ExecuteAsync(CancellationToken stoppingToken)
      {

         await Task.Run(() =>
          {
             var processor = serviceBusHelper.CreateServiceBusProcessor(config[ConfigKeys.SERVICEBUS_MOVE_QUEUE_NAME], settings.ServiceBusNamespaceName);
             processor.ProcessMessageAsync += ProcessMessageAsync;
             processor.ProcessErrorAsync += ExceptionReceivedHandler;
             log.LogInformation($"Starting FileMover with queue name: {config[ConfigKeys.SERVICEBUS_MOVE_QUEUE_NAME]}");
             while (true)
             {
                Thread.Sleep(10000);
                if (stoppingToken.IsCancellationRequested)
                {
                   log.LogInformation("Cancellation requested. Stopping the FileMover.");
                   break;
                }
             }
          });

      }
      private async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var fileMessage = args.Message.As<FileQueueMessage>();
         await tracker.TrackAndUpdate(fileMessage, "Moving original file");
         bool success = await MoveOriginalFileToCompleted(fileMessage.SourceFileName);
         if (success)
         {
            log.LogInformation($"Successfully move file {fileMessage.SourceFileName} to {settings.CompletedContainerName} container");
            await tracker.TrackAndUpdate(fileMessage, "Successfully moved original file");
            await args.CompleteMessageAsync(args.Message, args.CancellationToken);
         }
         else
         {
            log.LogInformation($"Failed move file {fileMessage.SourceFileName} to {settings.CompletedContainerName} container");
            await tracker.TrackAndUpdate(fileMessage, "Failed to move original file");
            await args.AbandonMessageAsync(args.Message);
         }

      }

      private Task ExceptionReceivedHandler(ProcessErrorEventArgs args)
      {
         log.LogError($"Error receiving message in FileMover ${args.Exception.Message}");
         return Task.CompletedTask;
      }
      // [Function("FileMover")]
      // public async Task Run([ServiceBusTrigger("%SERVICEBUS_MOVE_QUEUE_NAME%", Connection = "ServiceBusConnection")] ServiceBusReceivedMessage message)
      // {
      //    var fileMessage = message.As<FileQueueMessage>();
      //    log.LogInformation($"DocIntelligence triggered with message -- {fileMessage.ToString()}");

      //    await tracker.TrackAndUpdate(fileMessage, "Moving original file");
      //    bool success = await MoveOriginalFileToCompleted(fileMessage.SourceFileName);
      //    if (success)
      //    {
      //       log.LogInformation($"Successfully move file {fileMessage.SourceFileName} to {settings.CompletedContainerName} container");
      //       await tracker.TrackAndUpdate(fileMessage, "Successfully moved original file");
      //    }
      //    else
      //    {
      //       log.LogInformation($"Failed move file {fileMessage.SourceFileName} to {settings.CompletedContainerName} container");
      //       await tracker.TrackAndUpdate(fileMessage, "Failed to move original file");
      //    }

      // }

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
