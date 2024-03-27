using Azure.AI.DocumentIntelligence;
using Azure.Messaging.ServiceBus;
using AzureUtilities;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.Text;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace AiSearchIndexingFunction
{
   public class AiSearchIndexing
   {
      private readonly ILogger<AiSearchIndexing> log;
      private readonly SemanticUtility semanticUtility;
      public AiSearchIndexing(ILogger<AiSearchIndexing> logger, SemanticUtility semanticUtility)
      {
         log = logger;
         this.semanticUtility = semanticUtility;

      }

      [Function("AiSearchIndexing")]
      public async Task Run([ServiceBusTrigger("toindexqueue", Connection = "SERVICE_BUS_CONNECTION")] ServiceBusReceivedMessage message)
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
         var fileMessage = queueMessage.As<FileQueueMessage>();
         return await ProcessMessage(fileMessage);
      }
      public async Task<bool> ProcessMessage(FileQueueMessage fileMessage)
      {

         var contents = await GetFileContents(fileMessage);
         if (string.IsNullOrEmpty(contents))
         {
            log.LogError($"No content found in file {fileMessage.FileName}.");
            return false;
         }

         var contentLines = contents.Split(Environment.NewLine).ToList();

         var chunked = TextChunker.SplitPlainTextParagraphs(contentLines, semanticUtility.EmbeddingMaxTokens);

         await semanticUtility.StoreMemoryAsync(Path.GetFileNameWithoutExtension(fileMessage.FileName), contentLines);

         return true;

      }

      public async Task<string> GetFileContents(FileQueueMessage fileMessage)
      {

         var blobClient = Settings.ProcessResultsContainerClient.GetBlobClient(fileMessage.FileName);
         using (var stream = await blobClient.OpenReadAsync())
         using (var reader = new StreamReader(stream))
         {
            string contents = await reader.ReadToEndAsync();
            return contents;
         }
      }


      private Dictionary<string, string> SplitDocumentIntoPagesAndParagraphs(AnalyzeResult result, string fileName)
      {
         var content = "";
         bool contentFound = false;
         var taskList = new List<Task>();
         var docContent = new Dictionary<string, string>();

         //Split by page if there is content...
         log.LogInformation("Checking document data...");
         foreach (DocumentPage page in result.Pages)
         {

            for (int i = 0; i < page.Lines.Count; i++)
            {
               DocumentLine line = page.Lines[i];
               log.LogDebug($"  Line {i} has content: '{line.Content}'.");
               content += line.Content.ToString();
               contentFound = true;
            }

            if (!string.IsNullOrEmpty(content))
            {
               log.LogDebug("content = " + content);
               //taskList.Add(WriteAnalysisContentToBlob(name, page.PageNumber, content, log));
               docContent.Add(GetFileName(fileName, page.PageNumber), content);
            }
            content = "";
         }

         //Otherwise, split by collected paragraphs
         content = "";
         if (!contentFound && result.Paragraphs != null)
         {
            var counter = 0;
            foreach (DocumentParagraph paragraph in result.Paragraphs)
            {

               if (paragraph != null && !string.IsNullOrWhiteSpace(paragraph.Content))
               {
                  if (content.Length + paragraph.Content.Length < 4000)
                  {
                     content += paragraph.Content + Environment.NewLine;
                  }
                  else
                  {
                     //taskList.Add(WriteAnalysisContentToBlob(name, counter, content, log));
                     docContent.Add(GetFileName(fileName, counter), content);
                     counter++;

                     content = paragraph.Content + Environment.NewLine;
                  }
               }

            }

            //Add the last paragraph
            //taskList.Add(WriteAnalysisContentToBlob(name, counter, content, log));
            docContent.Add(GetFileName(fileName, counter), content);
         }

         return docContent;
      }

      private string GetFileName(string name, int counter)
      {
         string nameWithoutExtension = Path.GetFileNameWithoutExtension(name);
         string newName = nameWithoutExtension.Replace(".", "_");
         newName += $"_{counter.ToString().PadLeft(4, '0')}.json";
         return newName;
      }

   }
}
