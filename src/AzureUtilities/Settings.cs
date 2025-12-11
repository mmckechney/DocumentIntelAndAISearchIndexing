using Azure;
using Azure.AI.DocumentIntelligence;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System;
using System.Text.Json;
using HighVolumeProcessing.UtilityLibrary.Models;

namespace HighVolumeProcessing.UtilityLibrary
{
   public class Settings
   {
      public Settings(ILogger<Settings> settingsLogger, IConfiguration config)
      {
         this.settingsLogger = settingsLogger;
         this._config = config;
      }

      private ILogger<Settings> settingsLogger;
      private IConfiguration _config;

      public const string VectorSearchProfileName = "vectorSearch";
      private const string defaultAiIndexName = "general";

      private string _cosmosAccountEndpoint = string.Empty;
      public string CosmosAccountEndpoint
      {
         get
         {
            if (string.IsNullOrEmpty(_cosmosAccountEndpoint))
            {
               _cosmosAccountEndpoint = GetSettingsValue(ConfigKeys.COSMOS_ACCOUNT_ENDPOINT);
            }
            return _cosmosAccountEndpoint;
         }
      }

      private string _cosmosDbName = string.Empty;
      public string CosmosDbName
      {
         get
         {
            if (string.IsNullOrEmpty(_cosmosDbName))
            {
               _cosmosDbName = GetSettingsValue(ConfigKeys.COSMOS_DB_NAME);
            }
            return _cosmosDbName;
         }
      }


      private string _cosmosConstainerName = string.Empty;
      public string CosmosConstainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_cosmosConstainerName))
            {
               _cosmosConstainerName = GetSettingsValue(ConfigKeys.COSMOS_CONTAINER_NAME);
            }
            return _cosmosConstainerName;
         }
      }

      private string _aiSearchEndpoint = string.Empty;
      public string AiSearchEndpoint
      {
         get
         {
            if (string.IsNullOrEmpty(_aiSearchEndpoint))
            {
               _aiSearchEndpoint = GetSettingsValue(ConfigKeys.AZURE_AISEARCH_ENDPOINT);
            }
            return _aiSearchEndpoint;
         }
      }

      private string _AiSearchIndexName = string.Empty;
      public string AiSearchIndexName
      {
         get
         {
            if (string.IsNullOrEmpty(_AiSearchIndexName))
            {
               _AiSearchIndexName = GetSettingsValue(ConfigKeys.AZURE_AISEARCH_INDEXNAME, defaultAiIndexName);
            }
            return _AiSearchIndexName;
         }
      }

      private string _foundryProjectEndpoint = string.Empty;
      public string AzureFoundryProjectEndpoint
      {
         get
         {
            if (string.IsNullOrEmpty(_foundryProjectEndpoint))
            {
               _foundryProjectEndpoint = GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_PROJECT_ENDPOINT);
            }
            return _foundryProjectEndpoint;
         }
      }

      private string _foundryAgentId = string.Empty;
      public string AzureFoundryAgentId
      {
         get
         {
            if (string.IsNullOrEmpty(_foundryAgentId))
            {
               _foundryAgentId = GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_AGENT_ID);
            }
            return _foundryAgentId;
         }
      }

      private string _foundryChatDeployment = string.Empty;
      public string AzureFoundryChatDeployment
      {
         get
         {
            if (string.IsNullOrEmpty(_foundryChatDeployment))
            {
               _foundryChatDeployment = GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_CHAT_DEPLOYMENT);
            }
            return _foundryChatDeployment;
         }
      }

      private string _foundryEmbeddingDeployment = string.Empty;
      public string AzureFoundryEmbeddingDeployment
      {
         get
         {
            if (string.IsNullOrEmpty(_foundryEmbeddingDeployment))
            {
               _foundryEmbeddingDeployment = GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_EMBEDDING_DEPLOYMENT);
            }
            return _foundryEmbeddingDeployment;
         }
      }

      private string _foundryEmbeddingModel = string.Empty;
      public string AzureFoundryEmbeddingModel
      {
         get
         {
            if (string.IsNullOrEmpty(_foundryEmbeddingModel))
            {
               _foundryEmbeddingModel = GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_EMBEDDING_MODEL);
            }
            return _foundryEmbeddingModel;
         }
      }

      private string _completedContainerName = string.Empty;
      public string CompletedContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_completedContainerName))
            {
               _completedContainerName = GetSettingsValue(ConfigKeys.STORAGE_COMPLETED_CONTAINER_NAME);
            }
            return _completedContainerName;
         }
      }

      private string _customFieldQueueName = string.Empty;
      public string CustomFieldQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_customFieldQueueName))
            {
               _customFieldQueueName = GetSettingsValue(ConfigKeys.SERVICEBUS_CUSTOMFIELD_QUEUE_NAME);
            }
            return _customFieldQueueName;
         }
      }

      private string _docQueueName = string.Empty;
      public string DocumentQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_docQueueName))
            {
               _docQueueName = GetSettingsValue(ConfigKeys.SERVICEBUS_DOC_QUEUE_NAME);
            }
            return _docQueueName;
         }
      }

      private object lockObject = new object();
      private List<string>? _docIntelEndpointList;
      private List<DocAnalysisModel> _docIntelClients = new List<DocAnalysisModel>();
      public List<DocAnalysisModel> DocumentIntelligenceClients
      {
         get
         {
            lock (lockObject)
            {
               if (_docIntelClients.Count == 0)
               {
                  var endpoints = DocumentIntelligenceEndpointList;
                  if (endpoints.Count == 0)
                  {
                     throw new InvalidOperationException("No Document Intelligence endpoints are configured.");
                  }

                  int index = 0;
                  foreach (var endpoint in endpoints)
                  {
                     var intelClient = new DocumentIntelligenceClient(new Uri(endpoint), AadHelper.TokenCredential);
                     _docIntelClients.Add(new() { DocumentIntelligenceClient = intelClient, Endpoint = endpoint, Index = index });
                     index++;
                  }
               }
            }
            return _docIntelClients;
         }
      }

      public IReadOnlyList<string> DocumentIntelligenceEndpointList
      {
         get
         {
            if (_docIntelEndpointList == null)
            {
               var parsed = ParseEndpointList(_config[ConfigKeys.DOCUMENT_INTELLIGENCE_ENDPOINTS]);
               if (parsed.Count == 0 && !string.IsNullOrWhiteSpace(DocIntelEndpoint))
               {
                  parsed.Add(DocIntelEndpoint);
               }
               _docIntelEndpointList = parsed;
            }
            return _docIntelEndpointList;
         }
      }

      private string _documentProcessingModel = string.Empty;
      public string DocumentProcessingModel
      {
         get
         {
            if (string.IsNullOrEmpty(_documentProcessingModel))
            {
               _documentProcessingModel = GetSettingsValue(ConfigKeys.DOCUMENT_INTELLIGENCE_MODEL_NAME);
            }
            return _documentProcessingModel;
         }
      }

      private string _endpoint = string.Empty;
      public string DocIntelEndpoint
      {
         get
         {
            if (string.IsNullOrWhiteSpace(_endpoint))
            {
               _endpoint = GetSettingsValue(ConfigKeys.DOCUMENT_INTELLIGENCE_ENDPOINT);
            }
            return _endpoint;
         }
      }

      private int embeddingMaxTokens = 0;
      private int embeddingMaxTokensDefault = 8191; // Default value for max tokens
      public int EmbeddingMaxTokens
      {
         get
         {
            if (embeddingMaxTokens == 0)
            {
               int.TryParse(GetSettingsValue(ConfigKeys.AZURE_FOUNDRY_EMBEDDING_MAXTOKENS, embeddingMaxTokensDefault.ToString()), out embeddingMaxTokens);
            }
            return embeddingMaxTokens;
         }
      }

      private string _processResultsContainerName = string.Empty;
      public string ProcessResultsContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_processResultsContainerName))
            {
               _processResultsContainerName = GetSettingsValue(ConfigKeys.STORAGE_PROCESS_RESULTS_CONTAINER_NAME);
            }
            return _processResultsContainerName;
         }
      }

      private string _moveQueueName = string.Empty;
      public string MoveQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_moveQueueName))
            {
               _moveQueueName = GetSettingsValue(ConfigKeys.SERVICEBUS_MOVE_QUEUE_NAME);
            }
            return _moveQueueName;
         }
      }

      private string _serviceBusNamespaceName = string.Empty;
      public string ServiceBusNamespaceName
      {
         get
         {
            if (string.IsNullOrEmpty(_serviceBusNamespaceName))
            {
               _serviceBusNamespaceName = GetSettingsValue(ConfigKeys.SERVICEBUS_NAMESPACE_NAME);
            }
            return _serviceBusNamespaceName;
         }
      }

      private string _sourceContainerName = string.Empty;
      public string SourceContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_sourceContainerName))
            {
               _sourceContainerName = GetSettingsValue(ConfigKeys.STORAGE_SOURCE_CONTAINER_NAME); ;
            }
            return _sourceContainerName;
         }
      }

      private string _storageAccountName = string.Empty;
      public string StorageAccountName
      {
         get
         {
            if (string.IsNullOrEmpty(_storageAccountName))
            {
               _storageAccountName = GetSettingsValue(ConfigKeys.STORAGE_ACCOUNT_NAME);
            }
            return _storageAccountName;
         }
      }

      private string _toIndexQueueName = string.Empty;
      public string ToIndexQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_toIndexQueueName))
            {
               _toIndexQueueName = GetSettingsValue(ConfigKeys.SERVICEBUS_TOINDEX_QUEUE_NAME);
            }
            return _toIndexQueueName;
         }
      }

      private string GetSettingsValue(string variableName, string? defaultValue = null)
      {
         var value = _config[variableName];
         if(string.IsNullOrWhiteSpace(value))
         {
            if(string.IsNullOrWhiteSpace(defaultValue))
            {
               settingsLogger.LogError($"Setting variable {variableName} is Empty!");
            }
            else
            {
               settingsLogger.LogWarning($"Setting variable {variableName} is empty. Using default value of '{defaultValue}'!");
               value = defaultValue;
            }
         }
         
         return value;
      }
      private static List<string> ParseEndpointList(string? rawValue)
      {
         var endpoints = new List<string>();
         if (string.IsNullOrWhiteSpace(rawValue))
         {
            return endpoints;
         }

         var trimmed = rawValue.Trim();
         if (trimmed.StartsWith("["))
         {
            try
            {
               var parsed = JsonSerializer.Deserialize<List<string>>(trimmed);
               if (parsed != null)
               {
                  foreach (var item in parsed)
                  {
                     AddEndpointIfValid(endpoints, item);
                  }
               }
            }
            catch (JsonException ex)
            {
               throw new InvalidOperationException("Unable to parse DOCUMENT_INTELLIGENCE_ENDPOINTS as JSON array.", ex);
            }
         }
         else
         {
            var split = rawValue.Split(new[] { ',', ';', '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var item in split)
            {
               AddEndpointIfValid(endpoints, item);
            }
         }

         return endpoints;
      }

      private static void AddEndpointIfValid(List<string> endpoints, string? candidate)
      {
         if (string.IsNullOrWhiteSpace(candidate))
         {
            return;
         }

         var normalized = candidate.Trim();
         if (!string.IsNullOrWhiteSpace(normalized))
         {
            endpoints.Add(normalized);
         }
      }
   }
}
