using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.Text;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HighVolumeProcessing.AiSearchIndexingFunction
{

#pragma warning disable SKEXP0052 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0021 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0011 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0001 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0010 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0050 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
   public class AiSearchIndexing : BackgroundService
   {
      private readonly ILogger<AiSearchIndexing> log;
      private readonly SkHelper semanticUtility;
      private StorageHelper storageHelper;
      private AiSearchHelper aiSearchHelper;
      Settings settings;
      ServiceBusHelper serviceBusHelper;
      Tracker<AiSearchIndexing> tracker;
      IConfiguration config;
      public AiSearchIndexing(ILogger<AiSearchIndexing> logger, IConfiguration config, SkHelper semanticUtility, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, AiSearchHelper aiSearchHelper, Settings settings, Tracker<AiSearchIndexing> tracker)
      {
         log = logger;
         this.semanticUtility = semanticUtility;
         this.storageHelper = storageHelper;
         this.aiSearchHelper = aiSearchHelper;
         this.settings = settings;
         this.serviceBusHelper = serviceBusHelper;
         this.tracker = tracker;
         this.config = config;

      }


      protected async override Task ExecuteAsync(CancellationToken stoppingToken)
      {
         await Task.Run(() =>
         {
            var processor = serviceBusHelper.CreateServiceBusProcessor(config[ConfigKeys.SERVICEBUS_TOINDEX_QUEUE_NAME], settings.ServiceBusNamespaceName);
            processor.ProcessMessageAsync += ProcessMessageAsync;
            processor.ProcessErrorAsync += ExceptionReceivedHandler;
            log.LogInformation($"Starting AiSearchIndexing with queue name: {config[ConfigKeys.SERVICEBUS_TOINDEX_QUEUE_NAME]}");
            while (true)
            {
               Thread.Sleep(10000);
               if (stoppingToken.IsCancellationRequested)
               {
                  log.LogInformation("Cancellation requested. Stopping the AiSearchIndexing.");
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
            throw new Exception($"Failed to process message in AiSearchIndexing{args.Message.MessageId}.");
         }
         else
         {
            await args.CompleteMessageAsync(args.Message, args.CancellationToken);
         }
      }

      private async Task ExceptionReceivedHandler(ProcessErrorEventArgs args)
      {
         log.LogError($"Error receiving message in AiSearchIndexing${args.Exception.Message}");
      }



      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {
         fileMessage = await tracker.TrackAndUpdate(fileMessage, "Processing");
         var contents = await storageHelper.GetFileContents(settings.ProcessResultsContainerName, fileMessage.ProcessedFileName);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.SourceFileName}.");
            return false;
         }

         var contentLines = contents.Split(Environment.NewLine).ToList();

         var chunked = TextChunker.SplitPlainTextParagraphs(contentLines, settings.EmbeddingMaxTokens);

         fileMessage = await tracker.TrackAndUpdate(fileMessage, "Adding to Index");
         bool success = await aiSearchHelper.AddToIndexAsync(fileMessage.CustomIndexFieldValues, chunked, fileMessage.ProcessedFileName);

         if (!success)
         {
            return success;
         }

         fileMessage = await tracker.TrackAndUpdate(fileMessage, $"Sending to {settings.MoveQueueName}");
         var sbMessage = fileMessage.CloneWithOverrides().AsMessage();
         await serviceBusHelper.SendMessageAsync(settings.MoveQueueName, sbMessage);
         await tracker.TrackAndUpdate(fileMessage, $"Sent to {settings.MoveQueueName}");

         return success;

      }


   }
}
