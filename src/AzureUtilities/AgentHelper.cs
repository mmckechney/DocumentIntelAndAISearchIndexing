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

   public class AgentHelper
   {
      private AIAgent askQuestionsAgent;
      private AIAgent customFieldAgent;
      private IEmbeddingGenerator<string, Embedding<float>>? _embeddingGenerator;
      private ILogger<AgentHelper> log;
      private IConfiguration config;
      private ILoggerFactory logFactory;
      private bool initCalled = false;
      private Settings settings;
      private AIProjectClient foundryProjectClient;

      public AgentHelper(ILoggerFactory logFactory, IConfiguration config,  Settings settings)
      {
         log = logFactory.CreateLogger<AgentHelper>();
         this.config = config;
         this.logFactory = logFactory;
         this.settings = settings;
      }

      private readonly object lockObject = new object();

      private async Task InitAgents()
      {
         if(initCalled && askQuestionsAgent != null && customFieldAgent != null && _embeddingGenerator != null) return;

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

         var askQuestionsAgentName = "AskQuestions";
         string askQuestionsInstructions = @"  You are a document answering bot.  
  You will be provided with information from a document, and you are to answer the question based on the content provided.  
  Your are not to make up answers. Use the content provided to answer the question.";

         string askQuestionsDescription = "An agent that can answer questions about documents.";

         //AITool aiTool = AIFunctionFactory.Create(aiSearchHelper.SearchByCustomField);
         askQuestionsAgent = await GetFoundryAgent(askQuestionsAgentName);//, [aiTool]);

         if (askQuestionsAgent == null)
         {
            askQuestionsAgent = await CreateFoundryAgent(askQuestionsAgentName, chatDeployment, askQuestionsDescription, askQuestionsInstructions);//, [aiTool]);
         }

         if (askQuestionsAgent == null)
         {
            throw new NullReferenceException("The agent failed to initialize!");
         }

         var customFieldAgentName = "ExtractCustomFields";
         string customFieldInstructions = @"   You are a document analysis expert. 
   You will be provided with a document and you need to extract identifiers from the document.
   The identifier is called a ""load"" and can consist of a combination of letters and numbers.
   It might some times be referred to as a ""Shipping ID"", ""BOL"", ""Bill of Lading"", ""Load ID"", ""Load Number"", ""Load Code"", ""Load Reference"", ""Load Ref"", ""Load ID Number"", ""Load ID Code"", ""Load ID Ref"", ""Load ID Reference"", ""Booking Number"" or similar terms.""
   The load will not be a recognizable word and will be at least 8 characters long and may or may not be labeled as a load.
   Ignore any identifiers that are part of an item list or table
   The document may contain one or more loads.

   Return a list of loads in the following JSON format - 
      [ ""load1"",
         ""load2"",
         ""etc..""
      ] ";

         string customFieldDescription = "Extract Custom Fields from a document";

         customFieldAgent = await GetFoundryAgent(customFieldAgentName);//, [aiTool]);

         if (customFieldAgent == null)
         {
            customFieldAgent = await CreateFoundryAgent(customFieldAgentName, chatDeployment, customFieldDescription, customFieldInstructions);//, [aiTool]);
         }

         if (customFieldAgent == null)
         {
            throw new NullReferenceException("The agent failed to initialize!");
         }

         initCalled = true;
      }

      public async Task<string> AskQuestion(string question, string documentContent)
      {
         await InitAgents();
         log.LogInformation("Asking question about document...");

         string prompt = $"**QUESTION:** {question}\n**CONTENT:** {documentContent}";

         var response = await askQuestionsAgent.RunAsync(prompt);
         return response?.Text ?? string.Empty;
      }

      public async IAsyncEnumerable<string> AskQuestionStreaming(string question, string documentContent)
      {
         await InitAgents();
         log.LogDebug("Asking question about document via streaming...");

         string prompt = $"**QUESTION:** {question}\n**CONTENT:** {documentContent}";

         await foreach (var update in askQuestionsAgent.RunStreamingAsync(prompt))
         {
            if (!string.IsNullOrEmpty(update.Text))
            {
               yield return update.Text;
            }
         }
      }

      public async Task<CustomFields?> ExtractCustomField(string documentContent)
      {
         if (customFieldAgent == null) await InitAgents();
         var chunked = TextChunker.SplitPlainTextParagraphs(documentContent.Split('\n'), settings.EmbeddingMaxTokens);
         CustomFields? customFieldsObj = new();
         
         try
         {

            foreach (var chunk in chunked)
            {
               log.LogInformation("Extracting custom fields from document...");

               var response = await customFieldAgent.RunAsync(documentContent);
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
            if (_embeddingGenerator == null) await InitAgents();
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
