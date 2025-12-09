using System;
using System.Linq;
using System.Threading.Tasks;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

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
      Tracker<AiSearchIndexing> tracker;
      public AiSearchIndexing(ILogger<AiSearchIndexing> logger, SkHelper semanticUtility, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, AiSearchHelper aiSearchHelper, Settings settings, Tracker<AiSearchIndexing> tracker)
      {
         log = logger;
         this.semanticUtility = semanticUtility;
         this.storageHelper = storageHelper;
         this.aiSearchHelper = aiSearchHelper;
         this.settings = settings;
         this.serviceBusHelper = serviceBusHelper;
         this.tracker = tracker;

      }

      public async Task ProcessMessageAsync(FileQueueMessage fileMessage)
      {
         ArgumentNullException.ThrowIfNull(fileMessage);
         try
         {
            log.LogInformation("AiSearchIndexing triggered with message -- {Message}", fileMessage.ToString());
            bool success = await ProcessFileMessageAsync(fileMessage);
            if (!success)
            {
               throw new InvalidOperationException($"Failed to process message for {fileMessage.ProcessedFileName}.");
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe, "AiSearchIndexing failed for message {MessageId}", fileMessage.SourceFileName);
            await tracker.TrackAndUpdate(fileMessage, $"Failure in AiSearchIndexing: {exe.Message}");
            throw;
         }
      }

      private async Task<bool> ProcessFileMessageAsync(FileQueueMessage fileMessage)
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
