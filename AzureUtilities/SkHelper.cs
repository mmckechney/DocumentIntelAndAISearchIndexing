using HighVolumeProcessing.UtilityLibrary.Models; 
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.AzureAISearch;
using Microsoft.SemanticKernel.Connectors.AzureOpenAI;
using Microsoft.SemanticKernel.Embeddings;
using Microsoft.SemanticKernel.Memory;
using Microsoft.SemanticKernel.PromptTemplates.Handlebars;
using Microsoft.SemanticKernel.Text;
using System.Reflection;
namespace HighVolumeProcessing.UtilityLibrary
{
#pragma warning disable SKEXP0052 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0021 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
#pragma warning disable SKEXP0011 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

   public class SkHelper
   {
      Kernel kernel;
      ISemanticTextMemory semanticMemory;
      ILogger<SkHelper> log;
      IConfiguration config;
      ILoggerFactory logFactory;
      bool usingVolatileMemory = false;
      private bool initCalled = false;
      private int embeddingMaxTokens;
      private int embeddingMaxTokensDefault = 8100;
      private bool includeGeneralIndex = true;
      HttpClient client;
      Settings settings;

      ITextEmbeddingGenerationService _textEmbeddingService;
      private ITextEmbeddingGenerationService TextEmbeddingGenerationService
      {
         get
         {
            if (_textEmbeddingService == null)
            {
               if (!initCalled) InitKernel();
            }
            return _textEmbeddingService;
         }
         set
         {
            _textEmbeddingService = value;
         }
      }
      public SkHelper(ILoggerFactory logFactory, IConfiguration config,  Settings settings)
      {
         log = logFactory.CreateLogger<SkHelper>();
         this.config = config;
         this.logFactory = logFactory;
         this.settings = settings;

      }

      object lockObject = new object();
      private void InitKernel()
      {
         initCalled = true;
         lock (lockObject)
         {
            var openAIEndpoint = settings.AzureOpenAiEndpoint ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_ENDPOINT} in configuration.");
            var embeddingModel = settings.AzureOpenAiEmbeddingModel ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_EMBEDDING_MODEL} in configuration.");
            var embeddingDeploymentName = settings.AzureOpenAiEmbeddingDeployment ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_EMBEDDING_DEPLOYMENT} in configuration.");
            var apimSubscriptionKey = settings.ApimSubscriptionKey ?? throw new ArgumentException($"Missing {ConfigKeys.APIM_SUBSCRIPTION_KEY} in configuration.");
            var openAiChatDeploymentName = settings.AzureOpenAiChatDeployment ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_CHAT_DEPLOYMENT} in configuration.");
            var openAiChatModelName = settings.AzureOpenAiChatModel ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_CHAT_MODEL} in configuration.");

            var apiKey = "dummy";
            log.LogInformation($"Endpoint {openAIEndpoint} ");


            client = new HttpClient();
            client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apimSubscriptionKey);

            this.TextEmbeddingGenerationService = new AzureOpenAITextEmbeddingGenerationService(deploymentName: embeddingDeploymentName, modelId: embeddingModel,
                        endpoint: openAIEndpoint, apiKey: apiKey, httpClient: client);

            //Build and configure the kernel
            var kernelBuilder = Kernel.CreateBuilder();
            kernelBuilder.AddAzureOpenAIChatCompletion(deploymentName: openAiChatDeploymentName, modelId: openAiChatModelName,
                        endpoint: openAIEndpoint, apiKey: apiKey, httpClient: client);

            kernel = kernelBuilder.Build();

            var assembly = Assembly.GetExecutingAssembly();
            var resources = assembly.GetManifestResourceNames().ToList();
            Dictionary<string, KernelFunction> yamlPrompts = new();
            resources.ForEach(r =>
            {
               if (r.ToLower().EndsWith("yaml"))
               {
                  var tmp = r.Substring(0, r.LastIndexOf('.'));
                  var key = tmp.Substring(tmp.LastIndexOf('.') + 1);
                  using StreamReader reader = new(Assembly.GetExecutingAssembly().GetManifestResourceStream(r)!);
                  var content = reader.ReadToEnd();
                  var func = kernel.CreateFunctionFromPromptYaml(content, promptTemplateFactory: new HandlebarsPromptTemplateFactory());
                  yamlPrompts.Add(key, func);
               }
            });
            var plugin = KernelPluginFactory.CreateFromFunctions("YAMLPlugins", yamlPrompts.Select(y => y.Value).ToArray());
            kernel.Plugins.Add(plugin);
            
         }

      }

      public async Task<string> AskQuestion(string question, string documentContent)
      {
         if (kernel == null) InitKernel();
         log.LogInformation("Asking question about document...");
         var result = await kernel.InvokeAsync("YAMLPlugins", "AskQuestions", new() { { "question", question }, { "content", documentContent } });
         return result.GetValue<string>();
      }

      public async IAsyncEnumerable<string> AskQuestionStreaming(string question, string documentContent)
      {
         if (kernel == null) InitKernel();
         log.LogDebug("Asking question about document...");
         var result = kernel.InvokeStreamingAsync("YAMLPlugins", "AskQuestions", new() { { "question", question }, { "content", documentContent } });
         await foreach (var item in result)
         {
            yield return item.ToString();
         }
      }

      public async Task<CustomFields?> ExtractCustomField(string documentContent)
      {
         if (kernel == null) InitKernel();
         var chunked = TextChunker.SplitPlainTextParagraphs(documentContent.Split('\n'), settings.EmbeddingMaxTokens);
         string customFieldsString;
         CustomFields? customFieldsObj = new();
         try
         {
            foreach (var chunk in chunked)
            {
               log.LogInformation("Extracting custom fields from document...");
               var result = await kernel.InvokeAsync("YAMLPlugins", "ExtractCustomFields", new() { { "content", chunk } });
               customFieldsString = result.GetValue<string>().CleanJson();
               try
               {
                  var tmp = System.Text.Json.JsonSerializer.Deserialize<CustomFields>(customFieldsString);
                  if (tmp != null)
                  {
                     foreach (var field in tmp)
                     {
                        log.LogInformation($"Field: {field}");
                     }
                     customFieldsObj.AddRange(tmp);
                  }

               }
               catch (Exception ex)
               {
                  log.LogError($"Error deserializing custom fields: {ex.Message}");
               }
            }
            return customFieldsObj;
         }
         catch (Exception exe)
         {
            log.LogError($"Error extracting custom fields: {exe.Message}");
            return null;
         }

      }

      internal async Task<IList<float>> GetEmbeddingAsync(IList<string> content, string fileName)
      {
         try
         {
            if (kernel == null) InitKernel();
            log.LogInformation($"Getting embedding for {fileName}...");

            var embeddings = (await this.TextEmbeddingGenerationService.GenerateEmbeddingsAsync(content))
                .SelectMany(e => e.ToArray())
                .ToList();

            return embeddings;
         }
         catch (Exception exe)
         {
            log.LogError($"Failed to create embeddings for {fileName}. {exe.Message}");
            return null;
         }
      }
   }
}
