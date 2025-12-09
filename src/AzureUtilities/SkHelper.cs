using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.AI;
using Azure.AI.OpenAI;

namespace HighVolumeProcessing.UtilityLibrary
{

   public class SkHelper
   {
      private IChatClient? _chatClient;
      private IEmbeddingGenerator<string, Embedding<float>>? _embeddingGenerator;
      private ILogger<SkHelper> log;
      private IConfiguration config;
      private ILoggerFactory logFactory;
      private bool initCalled = false;
      private Settings settings;
      private Dictionary<string, PromptTemplate> _prompts = new();

      private IChatClient ChatClient
      {
         get
         {
            if (_chatClient == null)
            {
               if (!initCalled) InitClients();
            }
            return _chatClient!;
         }
      }

      private IEmbeddingGenerator<string, Embedding<float>> EmbeddingGenerator
      {
         get
         {
            if (_embeddingGenerator == null)
            {
               if (!initCalled) InitClients();
            }
            return _embeddingGenerator!;
         }
      }
      public SkHelper(ILoggerFactory logFactory, IConfiguration config,  Settings settings)
      {
         log = logFactory.CreateLogger<SkHelper>();
         this.config = config;
         this.logFactory = logFactory;
         this.settings = settings;

      }

      private readonly object lockObject = new object();
      
      private void InitClients()
      {
         initCalled = true;
         lock (lockObject)
         {
            var openAIEndpoint = settings.AzureOpenAiEndpoint ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_ENDPOINT} in configuration.");
            var embeddingDeploymentName = settings.AzureOpenAiEmbeddingDeployment ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_EMBEDDING_DEPLOYMENT} in configuration.");
            var openAiChatDeploymentName = settings.AzureOpenAiChatDeployment ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_OPENAI_CHAT_DEPLOYMENT} in configuration.");

            log.LogInformation($"Endpoint {openAIEndpoint}");

            var azureClient = new AzureOpenAIClient(
               new Uri(openAIEndpoint),
               AadHelper.TokenCredential,
               new AzureOpenAIClientOptions
               {
                  NetworkTimeout = TimeSpan.FromSeconds(120)
               });

            // Get the chat client as IChatClient with Microsoft.Extensions.AI
            var chatClient = azureClient.GetChatClient(openAiChatDeploymentName);
            _chatClient = chatClient.AsIChatClient();

            // Get the embedding client as IEmbeddingGenerator with Microsoft.Extensions.AI
            var embeddingClient = azureClient.GetEmbeddingClient(embeddingDeploymentName);
            _embeddingGenerator = embeddingClient.AsIEmbeddingGenerator();

            // Load YAML prompts
            _prompts = PromptLoader.LoadEmbeddedPrompts();
            log.LogInformation($"Loaded {_prompts.Count} prompt templates");
         }
      }

      public async Task<string> AskQuestion(string question, string documentContent)
      {
         if (_chatClient == null) InitClients();
         log.LogInformation("Asking question about document...");

         // Get the AskQuestions prompt template
         if (!_prompts.TryGetValue("AskQuestions", out var promptTemplate))
         {
            throw new InvalidOperationException("AskQuestions prompt template not found");
         }

         // Render the template with variables
         var renderedTemplate = PromptLoader.RenderTemplate(promptTemplate.Template, new Dictionary<string, string>
         {
            { "question", question },
            { "content", documentContent }
         });

         // Parse messages from the template
         var messages = PromptLoader.ParseMessages(renderedTemplate);
         var chatMessages = messages.Select(m => m.Role switch
         {
            "system" => new ChatMessage(ChatRole.System, m.Content),
            "user" => new ChatMessage(ChatRole.User, m.Content),
            _ => new ChatMessage(ChatRole.Assistant, m.Content)
         }).ToList();

         // Configure chat options
         var options = new ChatOptions
         {
            MaxOutputTokens = promptTemplate.ExecutionSettings.TryGetValue("default", out var settings) 
               ? settings.MaxTokens 
               : 3500,
            Temperature = promptTemplate.ExecutionSettings.TryGetValue("default", out var tempSettings) 
               ? (float)tempSettings.Temperature 
               : 0.9f
         };

         // Call the chat client
         var response = await ChatClient.GetResponseAsync(chatMessages, options);
         return response?.Text ?? string.Empty;
      }

      public async IAsyncEnumerable<string> AskQuestionStreaming(string question, string documentContent)
      {
         if (_chatClient == null) InitClients();
         log.LogDebug("Asking question about document...");

         // Get the AskQuestions prompt template
         if (!_prompts.TryGetValue("AskQuestions", out var promptTemplate))
         {
            throw new InvalidOperationException("AskQuestions prompt template not found");
         }

         // Render the template with variables
         var renderedTemplate = PromptLoader.RenderTemplate(promptTemplate.Template, new Dictionary<string, string>
         {
            { "question", question },
            { "content", documentContent }
         });

         // Parse messages from the template
         var messages = PromptLoader.ParseMessages(renderedTemplate);
         var chatMessages = messages.Select(m => m.Role switch
         {
            "system" => new ChatMessage(ChatRole.System, m.Content),
            "user" => new ChatMessage(ChatRole.User, m.Content),
            _ => new ChatMessage(ChatRole.Assistant, m.Content)
         }).ToList();

         // Configure chat options
         var options = new ChatOptions
         {
            MaxOutputTokens = promptTemplate.ExecutionSettings.TryGetValue("default", out var settings) 
               ? settings.MaxTokens 
               : 3500,
            Temperature = promptTemplate.ExecutionSettings.TryGetValue("default", out var tempSettings) 
               ? (float)tempSettings.Temperature 
               : 0.9f
         };

         // Stream the response
         await foreach (var update in ChatClient.GetStreamingResponseAsync(chatMessages, options))
         {
            if (!string.IsNullOrEmpty(update.Text))
            {
               yield return update.Text;
            }
         }
      }

      public async Task<CustomFields?> ExtractCustomField(string documentContent)
      {
         if (_chatClient == null) InitClients();
         var chunked = TextChunker.SplitPlainTextParagraphs(documentContent.Split('\n'), settings.EmbeddingMaxTokens);
         CustomFields? customFieldsObj = new();
         
         try
         {
            // Get the ExtractCustomFields prompt template
            if (!_prompts.TryGetValue("ExtractCustomFields", out var promptTemplate))
            {
               throw new InvalidOperationException("ExtractCustomFields prompt template not found");
            }

            foreach (var chunk in chunked)
            {
               log.LogInformation("Extracting custom fields from document...");
               
               // Render the template with variables
               var renderedTemplate = PromptLoader.RenderTemplate(promptTemplate.Template, new Dictionary<string, string>
               {
                  { "content", chunk }
               });

               // Parse messages from the template
               var messages = PromptLoader.ParseMessages(renderedTemplate);
               var chatMessages = messages.Select(m => m.Role switch
               {
                  "system" => new ChatMessage(ChatRole.System, m.Content),
                  "user" => new ChatMessage(ChatRole.User, m.Content),
                  _ => new ChatMessage(ChatRole.Assistant, m.Content)
               }).ToList();

               // Configure chat options
               var options = new ChatOptions
               {
                  MaxOutputTokens = promptTemplate.ExecutionSettings.TryGetValue("default", out var settings) 
                     ? settings.MaxTokens 
                     : 3500,
                  Temperature = promptTemplate.ExecutionSettings.TryGetValue("default", out var tempSettings) 
                     ? (float)tempSettings.Temperature 
                     : 0.9f
               };

               // Call the chat client
               var response = await ChatClient.GetResponseAsync(chatMessages, options);
               var customFieldsString = (response?.Text ?? string.Empty).CleanJson();
               
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
            if (_embeddingGenerator == null) InitClients();
            log.LogInformation($"Getting embedding for {fileName}...");

            var embeddings = await EmbeddingGenerator.GenerateAsync(content);
            
            // Flatten all embeddings into a single list
            var flattenedEmbeddings = embeddings
                .SelectMany(e => e.Vector.ToArray())
                .ToList();

            return flattenedEmbeddings;
         }
         catch (Exception exe)
         {
            log.LogError($"Failed to create embeddings for {fileName}. {exe.Message}");
            return null!;
         }
      }
   }
}
