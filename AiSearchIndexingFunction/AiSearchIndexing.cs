using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.Text;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace HighVolumeProcessing.AiSearchIndexingFunction
{
   public class AiSearchIndexing
   {
      private readonly ILogger<AiSearchIndexing> log;
      private readonly SkHelper semanticUtility;
      private StorageHelper storageHelper;
      private AiSearchHelper aiSearchHelper;
      Settings settings;
      ServiceBusHelper serviceBusHelper;
      public AiSearchIndexing(ILogger<AiSearchIndexing> logger, SkHelper semanticUtility, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, AiSearchHelper aiSearchHelper, Settings settings)
      {
         log = logger;
         this.semanticUtility = semanticUtility;
         this.storageHelper = storageHelper;
         this.aiSearchHelper = aiSearchHelper;
         this.settings = settings;
         this.serviceBusHelper = serviceBusHelper;

      }

      [Function("AiSearchIndexing")]
      public async Task Run([ServiceBusTrigger("%SERVICEBUS_TOINDEX_QUEUE_NAME%", Connection = "SERVICEBUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         try
         {
            var fileMessage = message.As<FileQueueMessage>();
            log.LogInformation($"AiSearchIndexing triggered with message -- {fileMessage.ToString()}");
            bool success = await ProcessMessage(fileMessage);
            if (!success)
            {
               throw new Exception($"Failed to process message {message.MessageId}.");
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe.Message);
            throw;

         }

      }
      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         var contents = await storageHelper.GetFileContents(settings.ProcessResultsContainerName, fileMessage.ProcessedFileName);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.SourceFileName}.");
            return false;
         }

         var contentLines = contents.Split(Environment.NewLine).ToList();

         var chunked = TextChunker.SplitPlainTextParagraphs(contentLines, settings.EmbeddingMaxTokens);

         bool success = await aiSearchHelper.AddToIndexAsync(fileMessage.CustomIndexFieldValues, chunked, fileMessage.ProcessedFileName);

         var sbMessage = fileMessage.CloneWithOverrides().AsMessage();
         await serviceBusHelper.SendMessageAsync(settings.MoveQueueName, sbMessage);

         return success;

      }


   }
}
