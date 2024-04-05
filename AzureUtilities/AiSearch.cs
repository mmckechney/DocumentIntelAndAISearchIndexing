using Azure.Search.Documents.Indexes;
using Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AzureUtilities
{
   public class AiSearch
   {

      SearchIndexClient client;
      ILogger<AiSearch> log;
      IConfiguration config;
      public AiSearch(ILogger<AiSearch> log, IConfiguration config)
      {
         this.log = log;
         this.config = config;
         var aISearchEndpoint = config["AZURE_AISEARCH_ENDPOINT"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ENDPOINT in configuration.");
         var aISearchAdminKey = config["AZURE_AISEARCH_ADMIN_KEY"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ADMIN_KEY in configuration.");


         // Create a client
         AzureKeyCredential credential = new AzureKeyCredential(aISearchAdminKey);
         client = new SearchIndexClient(new Uri(aISearchEndpoint), credential);
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
   }
}
