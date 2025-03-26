using Azure;
using Azure.AI.DocumentIntelligence;
//using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using AzureUtilities;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Polly;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace DocumentIntelligenceFunction
{
   public class DocIntelligence
   {
      private readonly ILogger<DocIntelligence> log;
      private StorageHelper storageHelper;
      private ServiceBusHelper serviceBusHelper;
      private List<DocAnalysisModel> intelClients = Settings.DocumentIntelligenceClients;

      public DocIntelligence(ILogger<DocIntelligence> logger, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper)
      {
         this.log = logger;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
      }

     
      [Function("DocIntelligence")]
      public async Task Run([ServiceBusTrigger("%SERVICE_BUS_DOC_QUEUE_NAME%", Connection = "SERVICE_BUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         try
         {
            bool success = await ProcessMessage(message);
            if (!success)
            {
               throw new Exception("Failed to process message");
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            throw;

         }
         return;
      }

      public async Task<bool> ProcessMessage(ServiceBusReceivedMessage queueMessage)
      {

         try
         {
            var fileMessage = queueMessage.As<FileQueueMessage>();
            return await ProcessMessage(fileMessage);
         }
         catch (Exception ex)
         {
            log.LogError(ex.ToString());
            return false;
         }
      }
      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         try
         {
            var uri = GetSourceFileUrl(fileMessage.FileName);
            var recogOutput = await ProcessDocumentIntelligence(uri, fileMessage.RecognizerIndex);
            if (recogOutput == null)
            {
               log.LogError($"Failed to get Document Intelligence output for file '{fileMessage.FileName}'. Stopping processing and abandoning message.");
               return false;
            }
            (bool saveResult, string processResultsFileName) = await SaveRecognitionResults(recogOutput, fileMessage.FileName);
            if (!saveResult)
            {
               log.LogError($"Unable to save results to output file for processed file '{fileMessage.FileName}'. Stopping processing and abandoning message.");
               return false;
            }
            var tagResult = await SetTagAndMetaDataOriginalFileAsProcessed(fileMessage.FileName);
            if (!tagResult)
            {
               log.LogWarning($"Unable to tag the original processed file '{fileMessage.FileName}'. Will still complete the message");
            }
            var messageResult = await SendQueueMessages(fileMessage.FileName, processResultsFileName);
            if (!tagResult)
            {
               log.LogWarning($"Unable to send 'processed' queue message for '{fileMessage.FileName}'. Will still complete the message");
            }
            return true;
         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            return false;
         }

      }
      public Uri GetSourceFileUrl(string sourceFile)
      {
         try
         {
            var sourceBlob = storageHelper.GetBlobClient(Settings.SourceContainerName, sourceFile); // Settings.SourceContainerClient.GetBlobClient(sourceFile);
            return sourceBlob.Uri;
         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            throw;
         }
      }
      private DocAnalysisModel GetDocIntelligenceClient(int index)
      {
         try
         {
            int clientCount = intelClients.Count;
            if (index < clientCount)
            {
               return intelClients.Where(i => i.Index == index).First();
            }
            else
            {
               int mod = index % clientCount;
               if (mod < clientCount)
               {
                  return intelClients.Where(i => i.Index == mod).First();
               }
               else
               {
                  return GetDocIntelligenceClient(index - 1);
               }
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            throw;
         }
      }
      public async Task<AnalyzeResult> ProcessDocumentIntelligence(Uri fileUri, int index)
      {
         Random jitterer = new Random();
         CancellationTokenSource source = new CancellationTokenSource();
         try
         {
            var intelClient = GetDocIntelligenceClient(index);


            //Retry policy to back off if too many calls are made to the Document Intelligence
            var retryPolicy = Policy.Handle<RequestFailedException>(e => e.Status == (int)HttpStatusCode.TooManyRequests)
                .WaitAndRetryAsync(5, retryAttempt => TimeSpan.FromSeconds(retryAttempt++) + TimeSpan.FromMilliseconds(jitterer.Next(0, 1000)));

            Operation<AnalyzeResult> operation1 = null;

            var pollyResult = await retryPolicy.ExecuteAndCaptureAsync(async token =>
            {
               operation1 = await intelClient.DocumentIntelligenceClient.AnalyzeDocumentAsync(waitUntil: WaitUntil.Completed, modelId: Settings.DocumentProcessingModel, uriSource: fileUri);
            }, source.Token);


            if (pollyResult.Outcome == OutcomeType.Failure)
            {
               log.LogError($"Policy retries failed for {fileUri}.");
               log.LogError($"Document Intelligence Endpoint Used: {intelClient.Endpoint}");
               log.LogError($"Obfuscated Key: {intelClient.Key}");
               log.LogError($"Document Model: {Settings.DocumentProcessingModel}");
               log.LogError($"Resulting exception: {pollyResult.FinalException}");
               return null;
            }


            //Using this sleep vs. operation.WaitForCompletion() to avoid over loading the endpoint
            do
            {
               System.Threading.Thread.Sleep(2000);
               await retryPolicy.ExecuteAndCaptureAsync(async token =>
               {
                  await operation1.UpdateStatusAsync();
               }, source.Token);

               if (pollyResult.Outcome == OutcomeType.Failure)
               {
                  log.LogError($"Policy retries failed for calling UpdateStatusAsync on {fileUri}. Resulting exception: {pollyResult.FinalException}");
               }

            } while (!operation1.HasCompleted);


            return operation1.Value;
         }
         catch (Azure.RequestFailedException are)
         {
            if (are.ErrorCode == "InvalidRequest")
            {
               log.LogError($"Failed to process file at URL:{fileUri.AbsoluteUri}. You may need to set permissions from the Document Intelligence to access your storage account. {are.ToString()}");
            }
            else
            {
               log.LogError($"Failed to process file at URL:{fileUri.AbsoluteUri}. {are.ToString()}");
            }
            return null;
         }
         catch (Exception exe)
         {

            log.LogError($"Failed to process file at URL:{fileUri.AbsoluteUri}. {exe.ToString()}");
            return null;
         }

      }
      public async Task<(bool, string)> SaveRecognitionResults(AnalyzeResult results, string sourceFileName)
      {
         return await SaveRecognitionResults(results, sourceFileName, false);

      }
      private async Task<(bool, string)> SaveRecognitionResults(AnalyzeResult results, string sourceFileName, bool isRetry)
      {
         string processedResultFileName = string.Empty;
         try
         {

            //string reultsJson = JsonSerializer.Serialize(results, new JsonSerializerOptions() { WriteIndented = true });
            processedResultFileName = $"{Path.GetFileNameWithoutExtension(sourceFileName)}.txt";
            Response<BlobContentInfo> resp = await storageHelper.UploadBlobAsync(Settings.ProcessResultsContainerName, processedResultFileName, results.Content);
            if (resp.GetRawResponse().Status >= 300)
            {
               log.LogError($"Error saving recognition results: {resp.GetRawResponse().ReasonPhrase}");
               return (false, "");
            }
         }
         catch (RequestFailedException re)
         {
            if (re.ErrorCode == "BlobAlreadyExists" && !isRetry)
            {
               processedResultFileName = Path.GetFileNameWithoutExtension(sourceFileName) + "-" + DateTime.UtcNow.ToString("yyyy-MM-dd-HH-mm");
               return await SaveRecognitionResults(results, processedResultFileName, true);
            }
            else
            {
               log.LogError($"Error saving recognition results. Tried alternate filename: {re.ToString()}");
               return (false, "");
            }
         }
         catch (Exception exe)
         {
            log.LogError($"Error saving recognition results: {exe.ToString()}");
            return (false, "");
         }

         return (true, processedResultFileName);
      }


      public async Task<bool> SetTagAndMetaDataOriginalFileAsProcessed(string sourceFileName)
      {
         try
         {
            var sourceBlob = storageHelper.GetBlobClient(Settings.SourceContainerName, sourceFileName); 

            var tags = new Dictionary<string, string>();
            tags.Add("Processed", "true");
            var resp = await sourceBlob.SetTagsAsync(tags);
            var resp2 = await sourceBlob.SetMetadataAsync(tags);
            return !resp.IsError && !(resp2.GetRawResponse().Status >= 300);

         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            return false;
         }
      }

      public async Task<bool> SendQueueMessages(string sourceFileName, string processResultsFile)
      {
         try
         {
            var sbMessage = new FileQueueMessage() { FileName = sourceFileName, ContainerName = Settings.SourceContainerName }.AsMessage();
            await serviceBusHelper.SendMessageAsync(Settings.ProcessedQueueName, sbMessage);


            sbMessage = new FileQueueMessage() { FileName = processResultsFile, ContainerName = Settings.ProcessResultsContainerName }.AsMessage();
            await serviceBusHelper.SendMessageAsync(Settings.CustomFieldQueueName, sbMessage);


            return true;

         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            return false;
         }
      }


   }
}
