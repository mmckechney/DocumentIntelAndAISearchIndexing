using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;
namespace HighVolumeProcessing.CustomFieldExtractionFunction
{
#pragma warning disable SKEXP0003 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class CustomFieldExtraction : BackgroundService
   {
      private SkHelper semanticUtility;
      ILogger<CustomFieldExtraction> log;
      IConfiguration config;
      StorageHelper storageHelper;
      ServiceBusHelper serviceBusHelper;
      Settings settings;
      Tracker<CustomFieldExtraction> tracker;
      public CustomFieldExtraction(ILogger<CustomFieldExtraction> log, IConfiguration config, SkHelper semanticMemory, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, Settings settings, Tracker<CustomFieldExtraction> tracker)
      {
         this.log = log;
         this.config = config;
         this.semanticUtility = semanticMemory;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
         this.settings = settings;
         this.tracker = tracker;
      }

      protected async override Task ExecuteAsync(CancellationToken stoppingToken)
      {

         await Task.Run(() =>
          {
             var processor = serviceBusHelper.CreateServiceBusProcessor(config[ConfigKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME], settings.ServiceBusNamespaceName);
             processor.ProcessMessageAsync += ProcessMessageAsync;
             processor.ProcessErrorAsync += ExceptionReceivedHandler;
             log.LogInformation($"Starting CustomFieldExtraction with queue name: {config[ConfigKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME]}");

             while (true)
             {
                Thread.Sleep(10000);
                if (stoppingToken.IsCancellationRequested)
                {
                   log.LogInformation("Cancellation requested. Stopping the CustomFieldExtraction.");
                   break;
                }
             }
          });

      }
      private async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var fileMessage = args.Message.As<FileQueueMessage>();
         bool success = await ProcessMessage(fileMessage);
         if (!success)
         {
            await args.AbandonMessageAsync(args.Message);
            throw new Exception($"Failed to process message in CustomFieldExtraction{args.Message.MessageId}.");
         }
         else
         {
            await args.CompleteMessageAsync(args.Message, args.CancellationToken);
         }
      }

      private Task ExceptionReceivedHandler(ProcessErrorEventArgs args)
      {
         log.LogError($"Error receiving message in CustomFieldExtraction ${args.Exception.Message}");
         return Task.CompletedTask;
      }
      // //function you can call to ask a question about a document.
      // [Function("CustomFieldExtraction")]
      // public async Task Run([ServiceBusTrigger("%SERVICEBUS_CUSTOMFIELD_QUEUE_NAME%", Connection = "ServiceBusConnection")] ServiceBusReceivedMessage message)
      // {
      //    var fileMessage = message.As<FileQueueMessage>();
      //    try
      //    {
      //       log.LogInformation($"CustomFieldExtraction triggered with message -- {fileMessage.ToString()}");

      //       await ProcessMessage(fileMessage);
      //    }
      //    catch (Exception exe)
      //    {
      //       log.LogError($"Failure in CustomFieldExtraction: {exe.Message}");
      //       await tracker.TrackAndUpdate(fileMessage, $"Failure in CustomFieldExtraction: {exe.Message}");
      //    }
      // }

      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         fileMessage = await tracker.TrackAndUpdate(fileMessage, "Processing");
         var contents = await storageHelper.GetFileContents(settings.ProcessResultsContainerName, fileMessage.ProcessedFileName);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.ProcessedFileName}.");
            return false;
         }

         fileMessage = await tracker.TrackAndUpdate(fileMessage, "Extracting Custom Field");
         var fields = await semanticUtility.ExtractCustomField(contents);

         if (fields == null || fields.Count == 0)
         {
            log.LogWarning($"No custom fields found in file {fileMessage.ProcessedFileName}.");
            fields = new CustomFields();
            fields.Add("NOT FOUND");
         }
         fileMessage = fileMessage.CloneWithOverrides(customIndexFieldValues: fields);

         fileMessage = await tracker.TrackAndUpdate(fileMessage, $"Sending to {settings.ToIndexQueueName}");
         var message = fileMessage.AsMessage();
         await serviceBusHelper.SendMessageAsync(settings.ToIndexQueueName, message);
         fileMessage = await tracker.TrackAndUpdate(fileMessage, $"Sent to {settings.ToIndexQueueName}");


         return true;
      }
   }



}


