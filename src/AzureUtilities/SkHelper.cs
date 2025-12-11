using Azure.AI.OpenAI;
using Azure.AI.Projects;
using Azure.AI.Projects.OpenAI;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Agents.AI;
using Microsoft.Azure.Cosmos.Serialization.HybridRow.Schemas;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.ClientModel.Primitives;

namespace HighVolumeProcessing.UtilityLibrary
{

   public class SkHelper
   {
      private AIAgent askQuestionsAgent;
      private IEmbeddingGenerator<string, Embedding<float>>? _embeddingGenerator;
      private ILogger<SkHelper> log;
      private IConfiguration config;
      private ILoggerFactory logFactory;
      private bool initCalled = false;
      private Settings settings;
      private AIProjectClient foundryProjectClient;
      private AiSearchHelper aiSearchHelper;
      private Dictionary<string, PromptTemplate> _prompts = new();

      public SkHelper(ILoggerFactory logFactory, IConfiguration config,  Settings settings)//, AiSearchHelper aiSearchHelper)
      {
         log = logFactory.CreateLogger<SkHelper>();
         this.config = config;
         this.logFactory = logFactory;
         this.settings = settings;
         // this.aiSearchHelper = aiSearchHelper;

      }

      private readonly object lockObject = new object();

      private async Task InitClients()
      {
         initCalled = true;

         if (askQuestionsAgent != null && _embeddingGenerator != null && _prompts.Count > 0)
         {
            return;
         }

         var projectEndpoint = settings.AzureFoundryProjectEndpoint ?? throw new ArgumentException($"Missing {ConfigKeys.AZURE_FOUNDRY_PROJECT_ENDPOINT} in configuration.");
         var embeddingDeployment = settings.AzureFoundryEmbeddingDeployment;
         var chatDeployment = settings.AzureFoundryChatDeployment;
         if (string.IsNullOrWhiteSpace(embeddingDeployment))
         {
            embeddingDeployment = settings.AzureFoundryEmbeddingModel;
         }

         if (string.IsNullOrWhiteSpace(embeddingDeployment))
         {
            throw new ArgumentException($"Missing embedding configuration. Set either {ConfigKeys.AZURE_FOUNDRY_EMBEDDING_DEPLOYMENT} or {ConfigKeys.AZURE_FOUNDRY_EMBEDDING_MODEL}.");
         }


         this.foundryProjectClient = new AIProjectClient(new Uri(projectEndpoint), AadHelper.TokenCredential);
         ClientConnection connection = this.foundryProjectClient.GetConnection(typeof(AzureOpenAIClient).FullName!);
         if (!connection.TryGetLocatorAsUri(out Uri? uri) || uri is null)
         {
            throw new InvalidOperationException("Invalid URI.");
         }

         uri = new Uri($"https://{uri.Host}");
         AzureOpenAIClient azureOpenAIClient = new AzureOpenAIClient(uri, AadHelper.TokenCredential);
         var embeddingClient = azureOpenAIClient.GetEmbeddingClient(embeddingDeployment);
         _embeddingGenerator = embeddingClient.AsIEmbeddingGenerator();

         var agentName = "AskQuestions";
         string instructions = @"  You are a document answering bot.  
  You will be provided with information from a document, and you are to answer the question based on the content provided.  
  Your are not to make up answers. Use the content provided to answer the question.";

         string description = "An agent that can answer questions about documents.";

         //AITool aiTool = AIFunctionFactory.Create(aiSearchHelper.SearchByCustomField);
         askQuestionsAgent = await GetFoundryAgent(agentName);//, [aiTool]);

         if (askQuestionsAgent == null)
         {
            askQuestionsAgent = await CreateFoundryAgent(agentName, chatDeployment, description, instructions);//, [aiTool]);
         }

         if (askQuestionsAgent == null)
         {
            throw new NullReferenceException("The agent failed to initialize!");
         }

      }

      public async Task<string> AskQuestion(string question, string documentContent)
      {
         if (askQuestionsAgent == null) await InitClients();
         log.LogInformation("Asking question about document...");

         // Get the AskQuestions prompt template
         if (!_prompts.TryGetValue("AskQuestions", out var promptTemplate))
         {
            throw new InvalidOperationException("AskQuestions prompt template not found");
         }

         // Render the template with variables
         var chatMessages = CreateChatMessages(promptTemplate, new Dictionary<string, string>
         {
            { "question", question },
            { "content", documentContent }
         });

         var agentRunOptions = CreateAgentRunOptions(promptTemplate);
         var response = await askQuestionsAgent.RunAsync(chatMessages, options: agentRunOptions);
         return response?.Text ?? string.Empty;
      }

      public async IAsyncEnumerable<string> AskQuestionStreaming(string question, string documentContent)
      {
         if (askQuestionsAgent == null) await InitClients();
         log.LogDebug("Asking question about document...");

         // Get the AskQuestions prompt template
         if (!_prompts.TryGetValue("AskQuestions", out var promptTemplate))
         {
            throw new InvalidOperationException("AskQuestions prompt template not found");
         }

         // Render the template with variables
         var chatMessages = CreateChatMessages(promptTemplate, new Dictionary<string, string>
         {
            { "question", question },
            { "content", documentContent }
         });

         var agentRunOptions = CreateAgentRunOptions(promptTemplate);

         await foreach (var update in askQuestionsAgent.RunStreamingAsync(chatMessages, options: agentRunOptions))
         {
            if (!string.IsNullOrEmpty(update.Text))
            {
               yield return update.Text;
            }
         }
      }

      public async Task<CustomFields?> ExtractCustomField(string documentContent)
      {
         if (askQuestionsAgent == null) InitClients();
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
               var chatMessages = CreateChatMessages(promptTemplate, new Dictionary<string, string>
               {
                  { "content", chunk }
               });

               var agentRunOptions = CreateAgentRunOptions(promptTemplate);

               var response = await askQuestionsAgent.RunAsync(chatMessages, options: agentRunOptions);
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
            if (_embeddingGenerator == null) await InitClients();
            log.LogInformation($"Getting embedding for {fileName}...");

            var embeddings = await _embeddingGenerator.GenerateAsync(content);
            
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

      private static List<ChatMessage> CreateChatMessages(PromptTemplate promptTemplate, Dictionary<string, string> variables)
      {
         var renderedTemplate = PromptLoader.RenderTemplate(promptTemplate.Template, variables);
         var messages = PromptLoader.ParseMessages(renderedTemplate);
         return messages.Select(m => m.Role switch
         {
            "system" => new ChatMessage(ChatRole.System, m.Content),
            "user" => new ChatMessage(ChatRole.User, m.Content),
            _ => new ChatMessage(ChatRole.Assistant, m.Content)
         }).ToList();
      }

      private static ChatClientAgentRunOptions CreateAgentRunOptions(PromptTemplate promptTemplate)
      {
         ExecutionSetting? execution = null;
         if (promptTemplate.ExecutionSettings.TryGetValue("default", out var settings))
         {
            execution = settings;
         }

         var chatOptions = new ChatOptions
         {
            MaxOutputTokens = execution?.MaxTokens ?? 3500,
            Temperature = (float)(execution?.Temperature ?? 0.9)
         };

         if (!string.IsNullOrWhiteSpace(execution?.ModelId))
         {
            chatOptions.ModelId = execution!.ModelId;
         }

         return new ChatClientAgentRunOptions
         {
            ChatOptions = chatOptions
         };
      }

      private async Task<AIAgent?> GetFoundryAgent(string agentName, params AITool[] tools)
      {

         var allAgents = new List<AgentRecord>();
         await foreach (var a in foundryProjectClient.Agents.GetAgentsAsync())
         {
            allAgents.Add(a);
         }

         // Filter by name
         var named = allAgents
            .Where(a => a.Name == agentName)
            .ToList();

         if (named.Count == 0)
         {
            return null;
         }

         //Need to add local tools each time you "get" the an existing agent
         return foundryProjectClient.GetAIAgent(agentName, tools)
               .AsBuilder()
               .UseOpenTelemetry(sourceName: "HighVolumeProcessing", configure: cfg =>
               {
                  cfg.EnableSensitiveData = true;
               })
               .Build();
      }

      private async Task<AIAgent?> CreateFoundryAgent(string name, string deployment, string description, string instructions, params AITool[] tools)
      {
       
         try
         {
            AIAgent? agent = null;
            await Task.Run(async () =>
            {
               agent = foundryProjectClient.CreateAIAgent(name: name, description: description, instructions: instructions, tools: tools, model: deployment)
                  .AsBuilder()
                    .UseOpenTelemetry(sourceName: "HighVolumeProcessing", configure: cfg =>
                    {
                       cfg.EnableSensitiveData = true;
                    })
                  .Build();

            });
            return agent;
         }
         catch (Exception exe)
         {
            log.LogError($"Failed to create Agent: {exe.ToString()}");
            return null;
         }
      }

   }
}
