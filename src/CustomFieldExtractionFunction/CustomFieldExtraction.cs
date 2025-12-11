using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Azure.Amqp.Framing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace HighVolumeProcessing.CustomFieldExtractionFunction
{
#pragma warning disable SKEXP0003 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class CustomFieldExtraction
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


      public async Task ProcessMessageAsync(FileQueueMessage fileMessage)
      {
         ArgumentNullException.ThrowIfNull(fileMessage);

         try
         {
            log.LogInformation("CustomFieldExtraction triggered with message -- {Message}", fileMessage.ToString());
            await ProcessMessage(fileMessage);
         }
         catch (Exception exe)
         {
            log.LogError(exe, "Failure in CustomFieldExtraction for file '{FileName}'", fileMessage.SourceFileName);
            await tracker.TrackAndUpdate(fileMessage, $"Failure in CustomFieldExtraction: {exe.Message}");
            throw;
         }
      }

      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         fileMessage = await tracker.TrackAndUpdate(fileMessage, "Processing");
         if (fileMessage.CustomIndexFieldValues == null || fileMessage.CustomIndexFieldValues.Count == 0)
         {
            fileMessage = await tracker.TrackAndUpdate(fileMessage, "No Custom Fields Specified. Abandoning extraction");
            fileMessage = fileMessage.CloneWithOverrides();
         }
         else
         {
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
         }

         fileMessage = await tracker.TrackAndUpdate(fileMessage, $"Sending to {settings.ToIndexQueueName}");
         var message = fileMessage.AsMessage();
         await serviceBusHelper.SendMessageAsync(settings.ToIndexQueueName, message);
         fileMessage = await tracker.TrackAndUpdate(fileMessage, $"Sent to {settings.ToIndexQueueName}");


         return true;
      }
   }



}


