using Azure;
using Azure.AI.DocumentIntelligence;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Runtime.CompilerServices;
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

      private string _cosmosDbConnectionString = string.Empty;
      public string CosmosDbConnectionString
      {
         get
         {
            if (string.IsNullOrEmpty(_cosmosDbConnectionString))
            {
               _cosmosDbConnectionString = GetSettingsValue(ConfigKeys.COSMOS_CONNECTION);
            }
            return _cosmosDbConnectionString;
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

      private string _AiSearchAdminKey = string.Empty;
      public string AiSearchAdminKey
      {
         get
         {
            if (string.IsNullOrEmpty(_AiSearchAdminKey))
            {
               _AiSearchAdminKey = GetSettingsValue(ConfigKeys.AZURE_AISEARCH_ADMIN_KEY);
            }
            return _AiSearchAdminKey;
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

      private string _apimSubscriptionKey = string.Empty;
      public string ApimSubscriptionKey
      {
         get
         {
            if (string.IsNullOrEmpty(_apimSubscriptionKey))
            {
               _apimSubscriptionKey = GetSettingsValue(ConfigKeys.APIM_SUBSCRIPTION_KEY);
            }
            return _apimSubscriptionKey;
         }
      }

      private string _azureOpenAiChatDeployment = string.Empty;
      public string AzureOpenAiChatDeployment
      {
         get
         {
            if (string.IsNullOrEmpty(_azureOpenAiChatDeployment))
            {
               _azureOpenAiChatDeployment = GetSettingsValue(ConfigKeys.AZURE_OPENAI_CHAT_DEPLOYMENT);
            }
            return _azureOpenAiChatDeployment;
         }
      }

      private string _azureOpenAiChatModel = string.Empty;
      public string AzureOpenAiChatModel
      {
         get
         {
            if (string.IsNullOrEmpty(_azureOpenAiChatModel))
            {
               _azureOpenAiChatModel = GetSettingsValue(ConfigKeys.AZURE_OPENAI_CHAT_MODEL);
            }
            return _azureOpenAiChatModel;
         }
      }

      private string _azureOpenAiEmbeddingDeployment = string.Empty;
      public string AzureOpenAiEmbeddingDeployment
      {
         get
         {
            if (string.IsNullOrEmpty(_azureOpenAiEmbeddingDeployment))
            {
               _azureOpenAiEmbeddingDeployment = GetSettingsValue(ConfigKeys.AZURE_OPENAI_EMBEDDING_DEPLOYMENT);
            }
            return _azureOpenAiEmbeddingDeployment;
         }
      }

      private string _azureOpenAiEmbeddingModel = string.Empty;
      public string AzureOpenAiEmbeddingModel
      {
         get
         {
            if (string.IsNullOrEmpty(_azureOpenAiEmbeddingModel))
            {
               _azureOpenAiEmbeddingModel = GetSettingsValue(ConfigKeys.AZURE_OPENAI_EMBEDDING_MODEL);
            }
            return _azureOpenAiEmbeddingModel;
         }
      }

      private string _azureOpenAiEndpoint = string.Empty;
      public string AzureOpenAiEndpoint
      {
         get
         {
            if (string.IsNullOrEmpty(_azureOpenAiEndpoint))
            {
               _azureOpenAiEndpoint = GetSettingsValue(ConfigKeys.AZURE_OPENAI_ENDPOINT);
            }
            return _azureOpenAiEndpoint;
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
      private List<DocAnalysisModel> _docIntelClients = new List<DocAnalysisModel>();
      public List<DocAnalysisModel> DocumentIntelligenceClients
      {
         get
         {
            lock (lockObject)
            {
               if (_docIntelClients.Count == 0)
               {

                  int index = 0;
                  foreach (var key in Keys)
                  {
                     var credential = new AzureKeyCredential(key);
                     var intelClient = new DocumentIntelligenceClient(new Uri(DocIntelEndpoint), credential);
                     _docIntelClients.Add(new() { DocumentIntelligenceClient = intelClient, Endpoint = DocIntelEndpoint, Key = key, Index = index });
                     index++;
                  }
               }
            }
            return _docIntelClients;
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
               int.TryParse(GetSettingsValue(ConfigKeys.AZURE_OPENAI_EMBEDDING_MAXTOKENS, embeddingMaxTokensDefault.ToString()), out embeddingMaxTokens);
            }
            return embeddingMaxTokens;
         }
      }

      private List<string> _keys = new List<string>();
      public List<string> Keys
      {
         get
         {
            lock (lockObject)
            {
               if (_keys.Count == 0)
               {
                  var tmp = GetSettingsValue(ConfigKeys.DOCUMENT_INTELLIGENCE_KEY);
                  if (!string.IsNullOrWhiteSpace(tmp))
                  {
                     _keys.AddRange(tmp.Split('|', StringSplitOptions.RemoveEmptyEntries));
                  }
               }
            }
            return _keys;
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
   }
}
