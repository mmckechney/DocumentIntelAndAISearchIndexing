using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Text.Json;
using System.Threading;
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

      public async Task<(string filename, string question, string customField)> GetFilenameAndQueryAsync(HttpRequest request, CancellationToken cancellationToken)
      {
         string filename = request.Query["filename"].ToString();
         string question = request.Query["question"].ToString();
         string customField = request.Query["customField"].ToString();

         string requestBody = string.Empty;
         if (request.ContentLength.GetValueOrDefault() > 0)
         {
            if (request.Body.CanSeek)
            {
               request.Body.Position = 0;
            }

            using var reader = new StreamReader(request.Body, leaveOpen: true);
            requestBody = await reader.ReadToEndAsync(cancellationToken);

            if (request.Body.CanSeek)
            {
               request.Body.Position = 0;
            }
         }

         if (!string.IsNullOrWhiteSpace(requestBody))
         {
            log.LogInformation(requestBody);
            try
            {
               using var document = JsonDocument.Parse(requestBody);
               var root = document.RootElement;
               filename = string.IsNullOrWhiteSpace(filename) ? GetProperty(root, "filename") ?? filename : filename;
               question = string.IsNullOrWhiteSpace(question) ? GetProperty(root, "question") ?? question : question;
               customField = string.IsNullOrWhiteSpace(customField) ? GetProperty(root, "customField") ?? customField : customField;
            }
            catch (JsonException ex)
            {
               log.LogWarning(ex, "Unable to parse request body for AskQuestions");
            }
         }

         if (!string.IsNullOrWhiteSpace(filename))
         {
            filename = Path.GetFileNameWithoutExtension(filename) ?? string.Empty;
         }


         log.LogInformation("filename = " + filename);
         log.LogInformation("question = " + question);
         log.LogInformation("customfield = " + customField);

         return (filename, question, customField);
      }

      private static string? GetProperty(JsonElement element, string propertyName)
      {
         if (element.ValueKind != JsonValueKind.Object)
         {
            return null;
         }

         if (element.TryGetProperty(propertyName, out var prop) && prop.ValueKind == JsonValueKind.String)
         {
            return prop.GetString();
         }

         return null;
      }

   }
}
