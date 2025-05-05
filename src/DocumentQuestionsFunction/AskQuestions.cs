using HighVolumeProcessing.UtilityLibrary; 
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace HighVolumeProcessing.DocumentQuestionsFunction
{
#pragma warning disable SKEXP0003 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class AskQuestions
   {
      private SkHelper semanticUtility;
      AiSearchHelper aiSearch;
      ILogger<AskQuestions> log;
      IConfiguration config;
      Helper common;
      Settings settings;
      public AskQuestions(ILogger<AskQuestions> log, IConfiguration config, Helper common, SkHelper semanticMemory, AiSearchHelper aiSearch, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.common = common;
         semanticUtility = semanticMemory;
         this.aiSearch = aiSearch;
         this.settings = settings;
      }


      //function you can call to ask a question about a document.
      [Function("AskQuestions")]
      public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequestData req)
      {
         log.LogInformation("C# HTTP trigger function processed a request for AskQuestions Function.");

         HttpResponseData resp;
         try
         {
            (string fileName, string question, string customField) = await common.GetFilenameAndQuery(req);

            if (string.IsNullOrWhiteSpace(question))
            {

               StringBuilder sb = new();
               sb.Append("To call this Function, please add a 'filename' and/or 'customField' and 'question' as query parameter to the URL for a GET or as JSON elements to the body for a POST.");
               var listResp = req.CreateResponse(System.Net.HttpStatusCode.OK);
               listResp.Body = new MemoryStream(Encoding.UTF8.GetBytes(sb.ToString()));
               return listResp;
            }

            string content = "";
            var results = await aiSearch.SearchByCustomField(fileName, customField, question);
            foreach (var result in results)
            {
               content += result.Text;
            }
            //Invoke Semantic Kernel to get answer

            if (content.Length == 0)
            {
               resp = req.CreateResponse(System.Net.HttpStatusCode.NoContent);
               resp.Body = new MemoryStream(Encoding.UTF8.GetBytes("Sorry, but I did not find a match based on your query."));
            }
            else
            {
               var responseMessage = await semanticUtility.AskQuestion(question, content);
               resp = req.CreateResponse(System.Net.HttpStatusCode.OK);
               resp.Body = new MemoryStream(Encoding.UTF8.GetBytes(responseMessage));
            }
            return resp;
         }
         catch (Exception ex)
         {
            resp = req.CreateResponse(System.Net.HttpStatusCode.BadRequest);
            resp.Body = new MemoryStream(Encoding.UTF8.GetBytes(ex.Message));
            return resp;
         }


      }



   }
}

