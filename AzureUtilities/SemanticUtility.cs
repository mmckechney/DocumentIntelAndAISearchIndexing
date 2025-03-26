using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.AzureAISearch;
using Microsoft.SemanticKernel.Connectors.AzureOpenAI;
using Microsoft.SemanticKernel.Memory;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Reflection;
using Microsoft.SemanticKernel.PromptTemplates.Handlebars;
using System.Collections;
using AzureUtilities.Models;
using Azure.Search.Documents.Indexes;
namespace AzureUtilities
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
         var aISearchEndpoint = config["AZURE_AISEARCH_ENDPOINT"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ENDPOINT in configuration.");
         var aISearchAdminKey = config["AZURE_AISEARCH_ADMIN_KEY"] ?? throw new ArgumentException("Missing AZURE_AISEARCH_ADMIN_KEY in configuration.");
         var apimSubscriptionKey = config["APIM_SUBSCRIPTION_KEY"] ?? throw new ArgumentException("Missing APIM_SUBSCRIPTION_KEY in configuration.");
         var openAiChatDeploymentName = config["AZURE_OPENAI_CHAT_DEPLOYMENT"] ?? throw new ArgumentException("Missing AZURE_OPENAI_CHAT_DEPLOYMENT in configuration.");
         var openAiChatModelName = config["AZURE_OPENAI_CHAT_MODEL"] ?? throw new ArgumentException("Missing AZURE_OPENAI_CHAT_MODEL in configuration.");

         if (bool.TryParse(config["AZURE_AISEARCH_INCLUDE_GENERAL_INDEX"], out bool tmpInclude))
         {
            includeGeneralIndex = tmpInclude;

         }
         var apiKey = "dummy";
         log.LogInformation($"Endpoint {openAIEndpoint} ");

         //Build and configure Memory Store
         IMemoryStore store = new AzureAISearchMemoryStore(aISearchEndpoint, aISearchAdminKey);
         
         client = new HttpClient();
         client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apimSubscriptionKey);

         var memBuilder = new MemoryBuilder()
             .WithMemoryStore(store)
             .WithTextEmbeddingGeneration(new AzureOpenAITextEmbeddingGenerationService(deploymentName: embeddingDeploymentName, modelId: embeddingModel, endpoint: openAIEndpoint, apiKey: apiKey, httpClient: client))
             .WithLoggerFactory(logFactory);

         semanticMemory = memBuilder.Build();

         //Build and configure the kernel
         var kernelBuilder = Kernel.CreateBuilder();
         kernelBuilder.AddAzureOpenAIChatCompletion(deploymentName: openAiChatDeploymentName, modelId: openAiChatModelName, endpoint: openAIEndpoint, apiKey: apiKey, httpClient: client);

         kernel = kernelBuilder.Build();

         var assembly = Assembly.GetExecutingAssembly();
         var resources = assembly.GetManifestResourceNames().ToList();
         Dictionary<string, KernelFunction> yamlPrompts = new();
         resources.ForEach(r =>
         {
            if (r.ToLower().EndsWith("yaml"))
            {
               var count = r.Split('.').Count();
               var key = count > 3 ? $"{r.Split('.')[count - 3]}_{r.Split('.')[count - 2]}" : r.Split('.')[count - 2];
               using StreamReader reader = new(Assembly.GetExecutingAssembly().GetManifestResourceStream(r)!);
               var content = reader.ReadToEnd();
               var func = kernel.CreateFunctionFromPromptYaml(content, promptTemplateFactory: new HandlebarsPromptTemplateFactory());
               yamlPrompts.Add(key, func);
            }
         });
         var plugin = KernelPluginFactory.CreateFromFunctions("YAMLPlugins", yamlPrompts.Select(y => y.Value).ToArray());
         kernel.Plugins.Add(plugin);
         initCalled = true;

      }
      public async Task StoreMemoryAsync(string collectionName, List<string> customFields, Dictionary<string, string> docFile)
      {
         var metadata = $"CustomField={string.Join(", ", customFields.ToArray())}"; 

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
                additionalMetadata: metadata,
                text: entry.Value);

            log.LogDebug($" #{++i} saved to {collectionName}.");
         }
      }
      public async Task StoreMemoryAsync(string collectionName, List<string> customFields, List<string> paragraphs)
      {
         Dictionary<string, string> docFile = new();
         for (int i = 0; i < paragraphs.Count; i++)
         {
            docFile.Add($"{collectionName}_{i.ToString().PadLeft(4, '0')}", paragraphs[i]);
         }
        // await StoreMemoryAsync(collectionName, customFields, docFile);

         if (includeGeneralIndex)
         {
            await StoreMemoryAsync("general", customFields, docFile);
         }
      }
      public async Task<IAsyncEnumerable<MemoryQueryResult>> SearchMemoryAsync(string collectionName, string customField, string query)
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

      public async Task<string> AskQuestion(string question, string documentContent)
      {
         if (!initCalled) InitMemoryAndKernel();
         log.LogInformation("Asking question about document...");
         var result = await kernel.InvokeAsync("YAMLPlugins", "AskQuestions", new() { { "question", question }, { "content", documentContent } });
         return result.GetValue<string>();
      }

      public async IAsyncEnumerable<string> AskQuestionStreaming(string question, string documentContent)
      {
         if (!initCalled) InitMemoryAndKernel();
         log.LogDebug("Asking question about document...");
         var result = kernel.InvokeStreamingAsync("YAMLPlugins", "AskQuestions", new() { { "question", question }, { "content", documentContent } });
         await foreach (var item in result)
         {
            yield return item.ToString();
         }
      }

      public async Task<CustomFields?> ExtractCustomField(string documentContent)
      {
         CustomFields? customFieldsObj = new();
         if (!initCalled) InitMemoryAndKernel();
         log.LogDebug("Extracting custom fields from document...");
         var result = await kernel.InvokeAsync("YAMLPlugins", "ExtractCustomFields", new() { { "content", documentContent } });
         var customFieldsString = result.GetValue<string>();
         try
         {
            customFieldsObj = System.Text.Json.JsonSerializer.Deserialize<CustomFields>(customFieldsString);
            if (customFieldsObj != null)
            {
               foreach (var field in customFieldsObj)
               {
                  log.LogDebug($"Field: {field}");
               }
            }
         }
         catch (Exception ex)
         {
            log.LogError($"Error deserializing custom fields: {ex.Message}");

         }
         return customFieldsObj;
      }



   }
}
