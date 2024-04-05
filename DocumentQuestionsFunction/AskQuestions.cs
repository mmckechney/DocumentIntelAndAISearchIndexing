using AzureUtilities;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.Memory;
using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace DocumentQuestionsFunction
{
#pragma warning disable SKEXP0003 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class AskQuestions
   {
      private SemanticUtility semanticUtility;
      AiSearch aiSearch;
      ILogger<AskQuestions> log;
      IConfiguration config;
      Helper common;

      public AskQuestions(ILogger<AskQuestions> log, IConfiguration config, Helper common, SemanticUtility semanticMemory, AiSearch aiSearch)
      {
         this.log = log;
         this.config = config;
         this.common = common;
         semanticUtility = semanticMemory;
         this.aiSearch = aiSearch;
      }


      //function you can call to ask a question about a document.
      [Function("AskQuestions")]
      public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequestData req)
      {
         log.LogInformation("C# HTTP trigger function processed a request for AskQuestions Function.");

         semanticUtility.InitMemoryAndKernel();

         try
         {
            (string filename, string question) = await common.GetFilenameAndQuery(req);

            if(filename == "general" && string.IsNullOrWhiteSpace(question))
            {
               var indexes = await aiSearch.ListAvailableIndexes();
               StringBuilder sb = new();
               sb.Append("To call this Function, please add a 'filename' and 'question' as query parameter to the URL for a GET or as JSON elements to the body for a POST.");
               sb.AppendLine();
               sb.AppendLine("Available File Names/Idexes:");
               indexes.ForEach(i => sb.AppendLine(i));
               var listResp = req.CreateResponse(System.Net.HttpStatusCode.OK);
               listResp.Body = new MemoryStream(Encoding.UTF8.GetBytes(sb.ToString()));
               return listResp;
            }

            var memories = await semanticUtility.SearchMemoryAsync(filename, question);
            string content = "";
            await foreach (MemoryQueryResult memoryResult in memories)
            {
               log.LogDebug("Memory Result = " + memoryResult.Metadata.Description);
               if (memoryResult.Metadata.Id.Contains("_") && filename != memoryResult.Metadata.Id.Substring(0, memoryResult.Metadata.Id.LastIndexOf('_')))
               {
                  filename = memoryResult.Metadata.Id.Substring(0, memoryResult.Metadata.Id.LastIndexOf('_'));
                  content += $"\nDocument Name: {filename}\n";
               }
               content += memoryResult.Metadata.Description;
            };
            //Invoke Semantic Kernel to get answer
            var responseMessage = await semanticUtility.AskQuestion(question, content);
            var resp = req.CreateResponse(System.Net.HttpStatusCode.OK);
            resp.Body = new MemoryStream(Encoding.UTF8.GetBytes(responseMessage));

            return resp;
         }
         catch (Exception ex)
         {
            var resp = req.CreateResponse(System.Net.HttpStatusCode.BadRequest);
            resp.Body = new MemoryStream(Encoding.UTF8.GetBytes(ex.Message));
            return resp;
         }


      }



   }
}

