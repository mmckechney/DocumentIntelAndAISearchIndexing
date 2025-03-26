using Azure.Search.Documents.Indexes;
using Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Azure.Search.Documents.Indexes.Models;
using AzureUtilities.Models;

namespace AzureUtilities
{
   public class AiSearchHelper
   {

      SearchIndexClient client;
      ILogger<AiSearchHelper> log;
      IConfiguration config;
      public AiSearchHelper(ILogger<AiSearchHelper> log, IConfiguration config)
      {
         this.log = log;
         this.config = config;
         var aISearchEndpoint = config["AZURE_AISEARCH_ENDPOINT"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ENDPOINT in configuration.");
         var aISearchAdminKey = config["AZURE_AISEARCH_ADMIN_KEY"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ADMIN_KEY in configuration.");


         // Create a client
         AzureKeyCredential credential = new AzureKeyCredential(aISearchAdminKey);
         client = new SearchIndexClient(new Uri(aISearchEndpoint), credential);
         CreateCustomFieldIndex();

      }
      public async Task<List<string>> ListAvailableIndexes()
      {
         List<string> names = new();
         await foreach (var page in client.GetIndexNamesAsync())
         {
            names.Add($"\"{page}\"");
         }
         return names;
      }

      public async Task<List<CustomFieldIndexModel>> SearchByCustomField(string customFieldValue, string query)
      {
         var searchClient = client.GetSearchClient("general");


         string customFieldQuery = "CustomField/any(c: c eq 'desired_value')";
         string textQuery = "text to match with cosine similarity";

         // Create the search options  
         var options = new SearchOptions
         {
            Filter = customFieldQuery,
            IncludeTotalCount = true
         };

         List<CustomFieldIndexModel> values = new();
         // Perform the search  
         SearchResults<CustomFieldIndexModel> response = await searchClient.SearchAsync<CustomFieldIndexModel>(textQuery, options);

         // Process the results  
         await foreach (SearchResult<CustomFieldIndexModel> result in response.GetResultsAsync())
         {
            values.Add(result.Document);
            log.LogInformation($"Id: {result.Document.Id}");
            log.LogInformation($"Text: {result.Document.Text}");
            log.LogInformation($"Description: {result.Document.Description}");
         }


         return values;

      }

      private void CreateCustomFieldIndex()
      {
         SearchIndex index = new SearchIndex("general")
         {
            Fields = new FieldBuilder().Build(typeof(CustomFieldIndexModel))
         };

         client.CreateOrUpdateIndex(index);
         log.LogInformation("Index created or updated successfully.");
      }
   }
}
