using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.IO;
using System.Threading.Tasks;

namespace HighVolumeProcessing.DocumentQuestionsFunction
{
   public class Helper
   {
      ILogger<Helper> log;
      IConfiguration config;
      public Helper(ILogger<Helper> log, IConfiguration config)
      {
         this.log = log;
         this.config = config;
      }

      public async Task<(string filename, string question, string customField)> GetFilenameAndQuery(HttpRequestData req)
      {
         string filename = req.Query["filename"];
         string question = req.Query["question"];
         string customField = req.Query["customField"];
         string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
         log.LogInformation(requestBody);
         dynamic data = JsonConvert.DeserializeObject(requestBody);
         filename = filename ?? data?.filename;
         question = question ?? data?.question;
         customField = customField ?? data?.customField;

         if (!string.IsNullOrWhiteSpace(filename))
         {
            filename = Path.GetFileNameWithoutExtension(filename);
         }


         log.LogInformation("filename = " + filename);
         log.LogInformation("question = " + question);
         log.LogInformation("customfield = " + customField);

         return (filename, question, customField);
      }

   }
}
