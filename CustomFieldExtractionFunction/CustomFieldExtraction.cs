using Azure.Messaging.ServiceBus;
using AzureUtilities;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.Text;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace CustomFieldExtractionFunction
{
#pragma warning disable SKEXP0003 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class CustomFieldExtraction
   {
      private SemanticUtility semanticUtility;
      ILogger<CustomFieldExtraction> log;
      IConfiguration config;
      Helper common;
      StorageHelper storageHelper;
      ServiceBusHelper serviceBusHelper;
      public CustomFieldExtraction(ILogger<CustomFieldExtraction> log, IConfiguration config, Helper common, SemanticUtility semanticMemory, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper)
      {
         this.log = log;
         this.config = config;
         this.common = common;
         this.semanticUtility = semanticMemory;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
      }


      //function you can call to ask a question about a document.
      [Function("CustomFieldExtraction")]
      public async Task Run([ServiceBusTrigger("%SERVICE_BUS_CUSTOMFIELD_QUEUE_NAME%", Connection = "SERVICE_BUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         log.LogInformation("C# HTTP trigger function processed a request for CustomFieldExtraction Function.");

         semanticUtility.InitMemoryAndKernel();
         await ProcessMessage(message);
      }

      public async Task<bool> ProcessMessage(ServiceBusReceivedMessage queueMessage)
      {
         var fileMessage = queueMessage.As<FileQueueMessage>();
         return await ProcessMessage(fileMessage);
      }
      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         var contents = await storageHelper.GetFileContents(Settings.ProcessResultsContainerName, fileMessage.FileName);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.FileName}.");
            return false;
         }
         var fields = await semanticUtility.ExtractCustomField(contents);

         var message = new FileQueueMessage() { ContainerName = Settings.ProcessResultsContainerName,FileName = fileMessage.FileName, RecognizerIndex = fileMessage.RecognizerIndex, CustomIndexFieldValues = fields }.AsMessage();
         await serviceBusHelper.SendMessageAsync(Settings.ToIndexQueueName, message);


         return true;

      }
   }



}


