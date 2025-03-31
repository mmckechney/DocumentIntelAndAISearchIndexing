using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary; 
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using HighVolumeProcessing.UtilityLibrary.Models;

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
      public CustomFieldExtraction(ILogger<CustomFieldExtraction> log, IConfiguration config, SkHelper semanticMemory, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.semanticUtility = semanticMemory;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
         this.settings = settings;
      }


      //function you can call to ask a question about a document.
      [Function("CustomFieldExtraction")]
      public async Task Run([ServiceBusTrigger("%SERVICEBUS_CUSTOMFIELD_QUEUE_NAME%", Connection = "SERVICEBUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         var fileMessage = message.As<FileQueueMessage>();
         log.LogInformation($"CustomFieldExtraction triggered with message -- {fileMessage.ToString()}");

         await ProcessMessage(fileMessage);
      }

      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         var contents = await storageHelper.GetFileContents(settings.ProcessResultsContainerName, fileMessage.ProcessedFileName);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.ProcessedFileName}.");
            return false;
         }
         var fields = await semanticUtility.ExtractCustomField(contents);


         var message = fileMessage.CloneWithOverrides(customIndexFieldValues: fields).AsMessage();
         await serviceBusHelper.SendMessageAsync(settings.ToIndexQueueName, message);


         return true;

      }
   }



}


