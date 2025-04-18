using HighVolumeProcessing.UtilityLibrary;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net;
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
      Settings settings;
      public AskQuestions(ILogger<AskQuestions> log, IConfiguration config, SkHelper semanticMemory, AiSearchHelper aiSearch, Settings settings)
      {
         this.log = log;
         this.config = config;
         semanticUtility = semanticMemory;
         this.aiSearch = aiSearch;
         this.settings = settings;
      }


      //function you can call to ask a question about a document.

      public async Task<(string, HttpStatusCode)> Question(string question, string customField, string fileName)
      {
         try
         {

            if (string.IsNullOrWhiteSpace(question))
            {

               StringBuilder sb = new();
               sb.Append("To call this Function, please add a 'fileNme' and/or 'customField' and 'question' as JSON elements to the body for a POST.");
               return (sb.ToString(), HttpStatusCode.BadRequest);
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
               return ("Sorry, but I did not find a match based on your query.", HttpStatusCode.NoContent);
            }
            else
            {
               var responseMessage = await semanticUtility.AskQuestion(question, content);
               return (responseMessage, HttpStatusCode.OK);
            }
         }
         catch (Exception ex)
         {
            return (ex.Message, HttpStatusCode.BadRequest);
         }


      }



   }
}

