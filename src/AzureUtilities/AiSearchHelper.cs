using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Models;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace HighVolumeProcessing.UtilityLibrary
{
   public class AiSearchHelper
   {

      SearchIndexClient client;
      ILogger<AiSearchHelper> log;
      IConfiguration config;
      SkHelper semanticUtility;
      Settings settings;
      public AiSearchHelper(ILogger<AiSearchHelper> log, IConfiguration config, SkHelper semanticUtility, Settings settings)
      {
         this.log = log;
         this.config = config;
         this.semanticUtility = semanticUtility;
         this.settings = settings;
         var aISearchEndpoint = settings.AiSearchEndpoint ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_AISEARCH_ENDPOINT} in configuration.");
         client = new SearchIndexClient(new Uri(aISearchEndpoint), AadHelper.TokenCredential);
         CreateCustomFieldIndex().Wait();

      }
      public async Task<List<string>> ListAvailableIndexes(bool quoted = true)
      {
         List<string> names = new();
         await foreach (var page in client.GetIndexNamesAsync())
         {
            if (quoted)
            {
               names.Add($"\"{page}\"");
            }
            else
            {
               names.Add($"{page}");
            }
         }
         return names;
      }

      public async Task<bool> AddToIndexAsync(List<string> customFieldValues, List<string> chunkedText, string fileName)
      {
         var searchClient = client.GetSearchClient(settings.AiSearchIndexName);
         var embeddings = await semanticUtility.GetEmbeddingAsync(chunkedText, fileName);

         if (embeddings == null)
         {
            log.LogError($"Unable to add file contents from {fileName} to the AI Search index {settings.AiSearchIndexName}");
            return false;
         }
         if (customFieldValues == null) customFieldValues = new List<string>();

         var batch = IndexDocumentsBatch.Create(
            IndexDocumentsAction.Upload(new CustomFieldIndexModel
            {
               Id = ComputeSha1Hash($"{fileName}{DateTime.Now.Ticks}"),
               FileName = fileName,
               Text = string.Join(Environment.NewLine, chunkedText),
               CustomField = customFieldValues,
               Embedding = embeddings

            }));

         try
         {
            await searchClient.IndexDocumentsAsync(batch);
            return true;
         }
         catch (Exception ex)
         {
            log.LogError($"Failed to index document {fileName}: {ex.ToString()}");
            return false;
         }
      }

      public async Task<List<CustomFieldIndexModel>> SearchByCustomField(string fileName, string customFieldValue, string query)
      {
         string customFieldQuery = string.Empty;
         var searchClient = client.GetSearchClient(settings.AiSearchIndexName);
         if (!string.IsNullOrWhiteSpace(customFieldValue))
         {
            customFieldQuery = $"CustomField/any(c: c eq '{customFieldValue}')";
         }

         var andS = customFieldQuery.Length > 0 ? " and " : string.Empty;
         if (!string.IsNullOrEmpty(fileName))
         {
            customFieldQuery += $"{andS} search.ismatch('{fileName}', 'FileName')";
         }

         log.LogDebug($"Custom field query: {customFieldQuery}");
         
         // Create the search options  
         var options = new SearchOptions
         {
            Filter = customFieldQuery,
            IncludeTotalCount = true
         };
 
         List<CustomFieldIndexModel> values = new();
         // Perform the search  
         SearchResults<CustomFieldIndexModel> response = await searchClient.SearchAsync<CustomFieldIndexModel>(query, options);

         // Process the results  
         await foreach (SearchResult<CustomFieldIndexModel> result in response.GetResultsAsync())
         {
            values.Add(result.Document);
            log.LogInformation($"Id: {result.Document.Id}");
            log.LogInformation($"Id: {result.Document.FileName}");
            log.LogInformation($"Text: {result.Document.Text}");
            log.LogInformation($"Description: {result.Document.Description}");
         }

         return values;
      }


      private bool indexConfimed = false;
      private async Task CreateCustomFieldIndex()
      {
         if (indexConfimed) return;

         var indexes = await this.ListAvailableIndexes(false);
         if (indexes.Contains(settings.AiSearchIndexName))
         {
            indexConfimed = true;
            return;
         }
         var fields = new FieldBuilder().Build(typeof(CustomFieldIndexModel));
         (var vectorSearchProfile, var algoConfig) = CreateVectorProfileAndAlgo();
         SearchIndex index = new SearchIndex(settings.AiSearchIndexName)
         {
            Fields = fields,
            VectorSearch = new VectorSearch()

         };

         index.VectorSearch.Profiles.Add(vectorSearchProfile);
         index.VectorSearch.Algorithms.Add(algoConfig);

         client.CreateIndex(index);
         log.LogInformation($"Index {settings.AiSearchIndexName} created or updated successfully.");



      }

      private (VectorSearchProfile, VectorSearchAlgorithmConfiguration) CreateVectorProfileAndAlgo()
      {
         var algoName = "searchAlgorithm";
         var vectorSearchAlgorithmConfig = new HnswAlgorithmConfiguration(name: algoName)
         {

            Parameters = new HnswParameters
            {
               M = 4,
               EfConstruction = 400,
               EfSearch = 500,
               Metric = "cosine"
            }
         };

         var vectorSearchProfile = new VectorSearchProfile(
            name: Settings.VectorSearchProfileName,
            algorithmConfigurationName: algoName);



         return (vectorSearchProfile, vectorSearchAlgorithmConfig);

      }

      private string ComputeSha1Hash(string input)
      {
         using (SHA1 sha1 = SHA1.Create())
         {
            byte[] inputBytes = Encoding.UTF8.GetBytes(input);
            byte[] hashBytes = sha1.ComputeHash(inputBytes);

            // Convert the byte array to a hexadecimal string
            StringBuilder sb = new StringBuilder();
            foreach (byte b in hashBytes)
            {
               sb.Append(b.ToString("x2"));
            }
            return sb.ToString();
         }
      }
   }
}
