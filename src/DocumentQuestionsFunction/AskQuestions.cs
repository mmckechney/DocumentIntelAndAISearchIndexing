using HighVolumeProcessing.UtilityLibrary;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace HighVolumeProcessing.DocumentQuestionsFunction
{
   public class AskQuestions
   {
      private AgentHelper semanticUtility;
      AiSearchHelper aiSearch;
      ILogger<AskQuestions> log;
      IConfiguration config;
      Helper common;
      Settings settings;
      public AskQuestions(ILogger<AskQuestions> log, IConfiguration config, Helper common, AgentHelper semanticMemory, AiSearchHelper aiSearch, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.common = common;
         semanticUtility = semanticMemory;
         this.aiSearch = aiSearch;
         this.settings = settings;
      }


      public async Task<IResult> HandleAsync(HttpRequest request, CancellationToken cancellationToken)
      {
         log.LogInformation("C# HTTP trigger function processed a request for AskQuestions Function.");

         try
         {
            (string fileName, string question, string customField) = await common.GetFilenameAndQueryAsync(request, cancellationToken);

            if (string.IsNullOrWhiteSpace(question))
            {
               var message = "To call this Function, please add a 'filename' and/or 'customField' and 'question' as query parameter to the URL for a GET or as JSON elements to the body for a POST.";
               return Results.Ok(message);
            }

            var contentBuilder = new StringBuilder();
            var results = await aiSearch.SearchByCustomField(fileName, question, customField);
            foreach (var result in results)
            {
               contentBuilder.Append(result.Text);
            }
            //Invoke Semantic Kernel to get answer

            if (contentBuilder.Length == 0)
            {
               return Results.Json(new { message = "Sorry, but I did not find a match based on your query." }, statusCode: StatusCodes.Status204NoContent);
            }

            var responseMessage = await semanticUtility.AskQuestion(question, contentBuilder.ToString());
            return Results.Ok(responseMessage);
         }
         catch (Exception ex)
         {
            log.LogError(ex, "AskQuestions failed");
            return Results.BadRequest(new { error = ex.Message });
         }


      }



   }
}

