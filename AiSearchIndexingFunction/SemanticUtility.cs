using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.AzureAISearch;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.SemanticKernel.Memory;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
namespace AiSearchIndexingFunction
{
#pragma warning disable SKEXP0052 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0021 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0011 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class SemanticUtility
   {
      Kernel kernel;
      ISemanticTextMemory semanticMemory;
      ILogger<SemanticUtility> log;
      IConfiguration config;
      ILoggerFactory logFactory;
      bool usingVolatileMemory = false;
      private bool initCalled = false;
      private int embeddingMaxTokens;
      private int embeddingMaxTokensDefault = 8100;
      private bool includeGeneralIndex = true;
      HttpClient client;
     
      public int EmbeddingMaxTokens
      {
         get
         {
            if (embeddingMaxTokens == 0)
            {
               int.TryParse(config["AZURE_OPENAI_EMBEDDING_MAXTOKENS"], out embeddingMaxTokens);
               if (embeddingMaxTokens == 0)
               {
                  log.LogWarning($"Missing AZURE_OPENAI_EMBEDDING_MAXTOKENS in configuration. Using default value of {embeddingMaxTokensDefault}");
                  embeddingMaxTokens = embeddingMaxTokensDefault;
               }
            }
            return embeddingMaxTokens;
         }
      }

      public SemanticUtility(ILoggerFactory logFactory, IConfiguration config)
      {
         log = logFactory.CreateLogger<SemanticUtility>();
         this.config = config;
         this.logFactory = logFactory;

      }


      public void InitMemoryAndKernel()
      {
         var openAIEndpoint = config["AZURE_OPENAI_ENDPOINT"] ?? throw new ArgumentException("Missing AZURE_OPENAI_ENDPOINT in configuration.");
         var embeddingModel = config["AZURE_OPENAI_EMBEDDING_MODEL"] ?? throw new ArgumentException("Missing AZURE_OPENAI_EMBEDDING_MODEL in configuration.");
         var embeddingDeploymentName = config["AZURE_OPENAI_EMBEDDING_DEPLOYMENT"] ?? throw new ArgumentException("Missing AZURE_OPENAI_EMBEDDING_DEPLOYMENT in configuration.");
         var apiKey = config["AZURE_OPENAI_KEY"]; //?? throw new ArgumentException("Missing AZURE_OPENAI_KEY in configuration.");
         var aISearchEndpoint = config["AZURE_AISEARCH_ENDPOINT"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ENDPOINT in configuration.");
         var aISearchAdminKey = config["AZURE_AISEARCH_ADMIN_KEY"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ADMIN_KEY in configuration.");
         var apimSubscriptionKey = config["APIM-SUBSCRIPTION-KEY"] ?? throw new ArgumentException("Missing APIM-SUBSCRIPTION-KEY in configuration.");
         if (bool.TryParse(config["AZURE_AISEARCH_INCLUDE_GENERAL_INDEX"], out bool tmpInclude))
         {
            includeGeneralIndex = tmpInclude;

         }
         apiKey = "dummy";
         log.LogInformation($"Endpoint {openAIEndpoint} ");
         //Build and configure Memory Store
         IMemoryStore store = new AzureAISearchMemoryStore(aISearchEndpoint, aISearchAdminKey);

         client = new HttpClient();
         client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apimSubscriptionKey);

         var memBuilder = new MemoryBuilder()
             .WithMemoryStore(store)
             .WithAzureOpenAITextEmbeddingGeneration(deploymentName: embeddingDeploymentName, modelId: embeddingModel, endpoint: openAIEndpoint, apiKey: apiKey, httpClient: client)
             .WithLoggerFactory(logFactory);

         semanticMemory = memBuilder.Build();
         initCalled = true;


      }
      public async Task StoreMemoryAsync(string collectionName, Dictionary<string, string> docFile)
      {
         if (!initCalled) InitMemoryAndKernel();
         log.LogInformation($"Storing memory to AI Search collection '{collectionName}'...");
         var i = 0;
         foreach (var entry in docFile)
         {
            await semanticMemory.SaveReferenceAsync(
                collection: collectionName,
                externalSourceName: "BlobStorage",
                externalId: entry.Key,
                description: entry.Value,
                text: entry.Value);

            log.LogDebug($" #{++i} saved to {collectionName}.");
         }
      }
      public async Task StoreMemoryAsync(string collectionName, List<string> paragraphs)
      {
         Dictionary<string, string> docFile = new();
         for (int i = 0; i < paragraphs.Count; i++)
         {
            docFile.Add(i.ToString(), paragraphs[i]);
         }
         await StoreMemoryAsync(collectionName, docFile);

         if (includeGeneralIndex)
         {
            await StoreMemoryAsync("general", docFile);
         }
      }
      public async Task<IAsyncEnumerable<MemoryQueryResult>> SearchMemoryAsync(string collectionName, string query)
      {
         if (!initCalled) InitMemoryAndKernel();
         log.LogDebug("\nQuery: " + query + "\n");
         var memoryResults = semanticMemory.SearchAsync(collectionName, query, limit: 30, minRelevanceScore: 0.5, withEmbeddings: true);
         int i = 0;
         await foreach (MemoryQueryResult memoryResult in memoryResults)
         {
            log.LogDebug($"Result {++i}:");
            log.LogDebug("  URL:     : " + memoryResult.Metadata.Id);
            log.LogDebug("  Text    : " + memoryResult.Metadata.Description);
            log.LogDebug("  Relevance: " + memoryResult.Relevance);
         }

         log.LogDebug("----------------------");

         return memoryResults;
      }

   }
}
