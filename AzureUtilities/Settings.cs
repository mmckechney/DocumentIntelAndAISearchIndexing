using Azure;
using Azure.AI.DocumentIntelligence;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Logging;

namespace AzureUtilities
{
   public class Settings
   {
      static Settings()
      {
         settingsLogger = new LoggerFactory().CreateLogger<Settings>();
      }
      private static ILogger<Settings> settingsLogger;
      private static string _endpoint = string.Empty;
      private static List<string> _keys = new List<string>();
      private static string _docQueueName = string.Empty;
      private static string _processedQueueName = string.Empty;
      private static string _sourceContainerName = string.Empty;
      private static string _toIndexQueueName = string.Empty;
      private static string _customFieldQueueName = string.Empty;
      private static string _processResultsContainerName = string.Empty;
      private static string _completedContainerName = string.Empty;
      private static string _storageAccountName = string.Empty;
      private static string _documentProcessingModel = string.Empty;
      private static string _serviceBusNamespaceName = string.Empty;

      private static List<DocAnalysisModel> _docIntelClients = new List<DocAnalysisModel>();

      public static string DocIntelEndpoint
      {
         get
         {
            if (string.IsNullOrWhiteSpace(_endpoint))
            {
               _endpoint = Environment.GetEnvironmentVariable("DOCUMENT_INTELLIGENCE_ENDPOINT");
            }
            return _endpoint;
         }
      }
      public static List<string> Keys
      {
         get
         {
            if (_keys.Count == 0)
            {
               var tmp = Environment.GetEnvironmentVariable("DOCUMENT_INTELLIGENCE_KEY");
               if (!string.IsNullOrWhiteSpace(tmp))
               {
                  _keys.AddRange(tmp.Split('|', StringSplitOptions.RemoveEmptyEntries));
               }
               else
               {
                  settingsLogger.LogError("DOCUMENT_INTELLIGENCE_KEY is empty");
               }
            }
            return _keys;
         }
      }
      public static string DocumentQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_docQueueName))
            {
               _docQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_DOC_QUEUE_NAME");
               if (string.IsNullOrEmpty(_docQueueName)) settingsLogger.LogError("SERVICE_BUS_DOC_QUEUE_NAME setting is empty!");
            }
            return _docQueueName;
         }
      }

      public static string ProcessedQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_processedQueueName))
            {
               _processedQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_PROCESSED_QUEUE_NAME");
               if (string.IsNullOrEmpty(_processedQueueName)) settingsLogger.LogError("SERVICE_BUS_PROCESSED_QUEUE_NAME setting is empty!");
            }
            return _processedQueueName;
         }
      }

      public static string CustomFieldQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_customFieldQueueName))
            {
               _processedQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_CUSTOMFIELD_QUEUE_NAME");
               if (string.IsNullOrEmpty(_customFieldQueueName)) settingsLogger.LogError("SERVICE_BUS_CUSTOMFIELD_QUEUE_NAME setting is empty!");
            }
            return _customFieldQueueName;
         }
      }

      public static string ToIndexQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_toIndexQueueName))
            {
               _toIndexQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_TOINDEX_QUEUE_NAME");
               if (string.IsNullOrEmpty(_toIndexQueueName)) settingsLogger.LogError("SERVICE_BUS_TOINDEX_QUEUE_NAME setting is empty!");
            }
            return _toIndexQueueName;
         }
      }
      public static string SourceContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_sourceContainerName))
            {
               _sourceContainerName = Environment.GetEnvironmentVariable("DOCUMENT_SOURCE_CONTAINER_NAME");
               if (string.IsNullOrEmpty(_sourceContainerName)) settingsLogger.LogError("DOCUMENT_SOURCE_CONTAINER_NAME setting is empty!");
            }
            return _sourceContainerName;

         }
      }

      public static string ProcessResultsContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_processResultsContainerName))
            {
               _processResultsContainerName = Environment.GetEnvironmentVariable("DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME");
               if (string.IsNullOrEmpty(_processResultsContainerName)) settingsLogger.LogError("DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME setting is empty!");
            }
            return _processResultsContainerName;

         }
      }
      public static string CompletedContainerName
      {
         get
         {
            if (string.IsNullOrEmpty(_completedContainerName))
            {
               _completedContainerName = Environment.GetEnvironmentVariable("DOCUMENT_COMPLETED_CONTAINER_NAME");
               if (string.IsNullOrEmpty(_completedContainerName)) settingsLogger.LogError("DOCUMENT_COMPLETED_CONTAINER_NAME setting is empty!");
            }
            return _completedContainerName;

         }
      }
      public static string StorageAccountName
      {
         get
         {
            if (string.IsNullOrEmpty(_storageAccountName))
            {
               _storageAccountName = Environment.GetEnvironmentVariable("DOCUMENT_STORAGE_ACCOUNT_NAME");
               if (string.IsNullOrEmpty(_storageAccountName)) settingsLogger.LogError("DOCUMENT_STORAGE_ACCOUNT_NAME setting is empty!");
            }
            return _storageAccountName;

         }
      }
      public static string DocumentProcessingModel
      {
         get
         {
            if (string.IsNullOrEmpty(_documentProcessingModel))
            {
               _documentProcessingModel = Environment.GetEnvironmentVariable("DOCUMENT_INTELLIGENCE_MODEL_NAME");
               if (string.IsNullOrWhiteSpace(_documentProcessingModel)) _documentProcessingModel = "prebuilt-layout";
            }
            return _documentProcessingModel;

         }
      }
      public static string ServiceBusNamespaceName
      {
         get
         {
            if (string.IsNullOrEmpty(_serviceBusNamespaceName))
            {
               _serviceBusNamespaceName = Environment.GetEnvironmentVariable("SERVICE_BUS_NAMESPACE_NAME");
               if (string.IsNullOrEmpty(_serviceBusNamespaceName)) settingsLogger.LogError("SERVICE_BUS_NAMESPACE_NAME setting is empty!");
            }
            return _serviceBusNamespaceName;

         }
      }

     

      public static List<DocAnalysisModel> DocumentIntelligenceClients
      {
         get
         {
            if (_docIntelClients.Count == 0)
            {
               int index = 0;
               foreach (var key in Keys)
               {
                  var credential = new AzureKeyCredential(key);
                  //var docIntelClient = new DocumentAnalysisClient(new Uri(Settings.Endpoint), credential);
                  var intelClient = new DocumentIntelligenceClient(new Uri(DocIntelEndpoint), credential);
                  _docIntelClients.Add(new() { DocumentIntelligenceClient = intelClient, Endpoint = Settings.DocIntelEndpoint, Key = key, Index = index });
                  index++;
               }
            }
            return _docIntelClients;
         }
      }
   }
}
