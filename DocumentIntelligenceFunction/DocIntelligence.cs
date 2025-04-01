using Azure;
using Azure.AI.DocumentIntelligence;
//using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs.Models;
using HighVolumeProcessing.UtilityLibrary; 
using HighVolumeProcessing.UtilityLibrary.Models; 
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Polly;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace HighVolumeProcessing.DocumentIntelligenceFunction
{
   public class DocIntelligence
   {
      private readonly ILogger<DocIntelligence> log;
      private StorageHelper storageHelper;
      private ServiceBusHelper serviceBusHelper;
      private Settings settings;
      private Tracker<DocIntelligence> tracker;
      public DocIntelligence(ILogger<DocIntelligence> logger, StorageHelper storageHelper, ServiceBusHelper serviceBusHelper, Settings settings, Tracker<DocIntelligence> tracker)
      {
         this.log = logger;
         this.storageHelper = storageHelper;
         this.serviceBusHelper = serviceBusHelper;
         
         this.settings = settings;
         this.tracker = tracker;
      }


      [Function("DocIntelligence")]
      public async Task Run([ServiceBusTrigger("%SERVICEBUS_DOC_QUEUE_NAME%", Connection = "SERVICEBUS_CONNECTION")] ServiceBusReceivedMessage message)
      {
         var fileMessage = message.As<FileQueueMessage>();
         try
         {
            log.LogInformation($"DocIntelligence triggered with message -- {fileMessage.ToString()}");

            bool success = await ProcessMessage(fileMessage);
            if (!success)
            {
               throw new Exception("Failed to process message");
            }
         }
         catch (Exception exe)
         {
            log.LogError(exe.ToString());
            await tracker.TrackAndUpdate(fileMessage, $"Failure in DocIntelligence: {exe.Message}");
            throw;

         }
         return;
      }
      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         try
         {
            fileMessage = await tracker.TrackAndUpdate(fileMessage, "Processing");
            var uri = GetSourceFileUrl(fileMessage.SourceFileName);
            var recogOutput = await ProcessDocumentIntelligence(uri, fileMessage.RecognizerIndex);
            if (recogOutput == null)
            {
               log.LogError($"Failed to get Document Intelligence output for file '{fileMessage.SourceFileName}'. Stopping processing and abandoning message.");
               return false;
            }
            (bool saveResult, string processResultsFileName) = await SaveRecognitionResults(recogOutput, fileMessage.SourceFileName);
            if (!saveResult)
            {
               log.LogError($"Unable to save results to output file for processed file '{fileMessage.SourceFileName}'. Stopping processing and abandoning message.");
               return false;
            }
            var tagResult = await SetTagAndMetaDataOriginalFileAsProcessed(fileMessage.SourceFileName);
            if (!tagResult)
            {
               log.LogWarning($"Unable to tag the original processed file '{fileMessage.SourceFileName}'. Will still complete the message");
            }

            fileMessage.CloneWithOverrides(containerName: settings.ProcessResultsContainerName, processedFileName: processResultsFileName).AsMessage();

            var newMsg = fileMessage.CloneWithOverrides(containerName: settings.ProcessResultsContainerName, processedFileName: processResultsFileName);
            newMsg = await tracker.TrackAndUpdate(newMsg, $"Sending to {settings.CustomFieldQueueName}");

            var sbMessage = newMsg.AsMessage();
            await serviceBusHelper.SendMessageAsync(settings.CustomFieldQueueName, sbMessage);
            newMsg = await tracker.TrackAndUpdate(newMsg, $"Sent to {settings.CustomFieldQueueName}");

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
            var sourceBlob = storageHelper.GetBlobClient(settings.SourceContainerName, sourceFile);
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
            int clientCount = settings.DocumentIntelligenceClients.Count;
            if (index < clientCount)
            {
               return settings.DocumentIntelligenceClients.Where(i => i.Index == index).First();
            }
            else
            {
               int mod = index % clientCount;
               if (mod < clientCount)
               {
                  return settings.DocumentIntelligenceClients.Where(i => i.Index == mod).First();
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

            Operation<AnalyzeResult> operationRes = null;

            AnalyzeDocumentOptions opts = new AnalyzeDocumentOptions(modelId: settings.DocumentProcessingModel, uriSource: fileUri)
            {
               OutputContentFormat = DocumentContentFormat.Markdown,
            };

            var pollyResult = await retryPolicy.ExecuteAndCaptureAsync(async token =>
            {
               operationRes = await intelClient.DocumentIntelligenceClient.AnalyzeDocumentAsync(waitUntil: WaitUntil.Completed, opts);
            }, source.Token);


            if (pollyResult.Outcome == OutcomeType.Failure)
            {
               log.LogError($"Policy retries failed for {fileUri}.");
               log.LogError($"Document Intelligence Endpoint Used: {intelClient.Endpoint}");
               log.LogError($"Obfuscated Key: {intelClient.Key}");
               log.LogError($"Document Model: {settings.DocumentProcessingModel}");
               log.LogError($"Resulting exception: {pollyResult.FinalException}");
               return null;
            }


            //Using this sleep vs. operation.WaitForCompletion() to avoid over loading the endpoint
            do
            {
               System.Threading.Thread.Sleep(2000);
               await retryPolicy.ExecuteAndCaptureAsync(async token =>
               {
                  await operationRes.UpdateStatusAsync();
               }, source.Token);

               if (pollyResult.Outcome == OutcomeType.Failure)
               {
                  log.LogError($"Policy retries failed for calling UpdateStatusAsync on {fileUri}. Resulting exception: {pollyResult.FinalException}");
               }

            } while (!operationRes.HasCompleted);


            return operationRes.Value;
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
            processedResultFileName = $"{Path.GetFileNameWithoutExtension(sourceFileName)}.md";
            Response<BlobContentInfo> resp = await storageHelper.UploadBlobAsync(settings.ProcessResultsContainerName, processedResultFileName, results.Content);
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
            var sourceBlob = storageHelper.GetBlobClient(settings.SourceContainerName, sourceFileName);

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


   }
}
