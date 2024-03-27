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
         var loggerFactory = new LoggerFactory();
         storageLogger = loggerFactory.CreateLogger<StorageHelper>();
         sblogger = loggerFactory.CreateLogger<ServiceBusHelper>();
      }
      private static ILogger<StorageHelper> storageLogger;
      private static ILogger<ServiceBusHelper> sblogger;
      private static string _endpoint = string.Empty;
      private static List<string> _keys = new List<string>();
      private static string _queueName = string.Empty;
      private static string _processedQueueName = string.Empty;
      private static string _sourceContainerName = string.Empty;
      private static string _toIndexQueueName = string.Empty;
      private static string _processResultsContainerName = string.Empty;
      private static string _completedContainerName = string.Empty;
      private static string _storageAccountName = string.Empty;
      private static string _documentProcessingModel = string.Empty;
      private static string _serviceBusNamespaceName = string.Empty;
      private static BlobContainerClient _sourceContainerClient;
      private static BlobContainerClient _processResultsContainerClient;
      private static BlobContainerClient _completedContainerClient;
      private static ServiceBusSender _serviceBusSenderClient;
      private static ServiceBusSender _serviceBusProcessedSenderClient;
      private static ServiceBusSender _serviceBusToIndexSenderClient;
      private static List<DocAnalysisModel> _docIntelClients = new List<DocAnalysisModel>();

      public static string Endpoint
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
                  storageLogger.LogError("DOCUMENT_INTELLIGENCE_KEY is empty");
               }
            }
            return _keys;
         }
      }
      public static string QueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_queueName))
            {
               _queueName = Environment.GetEnvironmentVariable("SERVICE_BUS_QUEUE_NAME");
               if (string.IsNullOrEmpty(_queueName)) sblogger.LogError("SERVICE_BUS_QUEUE_NAME setting is empty!");
            }
            return _queueName;
         }
      }

      public static string ProcessedQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_processedQueueName))
            {
               _processedQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_PROCESSED_QUEUE_NAME");
               if (string.IsNullOrEmpty(_processedQueueName)) sblogger.LogError("SERVICE_BUS_PROCESSED_QUEUE_NAME setting is empty!");
            }
            return _processedQueueName;
         }
      }

      public static string ToIndexQueueName
      {
         get
         {
            if (string.IsNullOrEmpty(_toIndexQueueName))
            {
               _toIndexQueueName = Environment.GetEnvironmentVariable("SERVICE_BUS_TOINDEX_QUEUE_NAME");
               if (string.IsNullOrEmpty(_toIndexQueueName)) sblogger.LogError("SERVICE_BUS_TOINDEX_QUEUE_NAME setting is empty!");
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
               if (string.IsNullOrEmpty(_sourceContainerName)) storageLogger.LogError("DOCUMENT_SOURCE_CONTAINER_NAME setting is empty!");
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
               if (string.IsNullOrEmpty(_processResultsContainerName)) storageLogger.LogError("DOCUMENT_PROCESS_RESULTS_CONTAINER_NAME setting is empty!");
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
               if (string.IsNullOrEmpty(_completedContainerName)) storageLogger.LogError("DOCUMENT_COMPLETED_CONTAINER_NAME setting is empty!");
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
               if (string.IsNullOrEmpty(_storageAccountName)) storageLogger.LogError("DOCUMENT_STORAGE_ACCOUNT_NAME setting is empty!");
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
               if (string.IsNullOrWhiteSpace(_documentProcessingModel)) _documentProcessingModel = "prebuilt-read";
            }
            return _documentProcessingModel;

         }
      }
      public static string ServiceBusNameSpaceName
      {
         get
         {
            if (string.IsNullOrEmpty(_serviceBusNamespaceName))
            {
               _serviceBusNamespaceName = Environment.GetEnvironmentVariable("SERVICE_BUS_NAMESPACE_NAME");
               if (string.IsNullOrEmpty(_serviceBusNamespaceName)) storageLogger.LogError("SERVICE_BUS_NAMESPACE_NAME setting is empty!");
            }
            return _serviceBusNamespaceName;

         }
      }
      public static BlobContainerClient SourceContainerClient
      {
         get
         {
            if (_sourceContainerClient == null)
            {

               _sourceContainerClient = new StorageHelper(storageLogger).CreateBlobContainerClient(SourceContainerName, StorageAccountName);
            }
            return _sourceContainerClient;
         }
      }

      public static BlobContainerClient ProcessResultsContainerClient
      {
         get
         {
            if (_processResultsContainerClient == null)
            {
               _processResultsContainerClient = new StorageHelper(storageLogger).CreateBlobContainerClient(ProcessResultsContainerName, StorageAccountName);
            }
            return _processResultsContainerClient;
         }
      }
      public static BlobContainerClient CompletedContainerClient
      {
         get
         {
            if (_completedContainerClient == null)
            {
               _completedContainerClient = new StorageHelper(storageLogger).CreateBlobContainerClient(CompletedContainerName, StorageAccountName);
            }
            return _completedContainerClient;
         }
      }
      public static ServiceBusSender ServiceBusSenderClient
      {
         get
         {
            if (_serviceBusSenderClient == null)
            {
               _serviceBusSenderClient = new ServiceBusHelper(sblogger).CreateServiceBusSender(ServiceBusNameSpaceName, QueueName);
            }
            return _serviceBusSenderClient;
         }
      }

      public static ServiceBusSender ServiceBusProcessedSenderClient
      {
         get
         {
            if (_serviceBusProcessedSenderClient == null)
            {
               _serviceBusProcessedSenderClient = new ServiceBusHelper(sblogger).CreateServiceBusSender(ServiceBusNameSpaceName, ProcessedQueueName);
            }
            return _serviceBusProcessedSenderClient;
         }
      }

      public static ServiceBusSender ServiceBusToIndexSenderClient
      {
         get
         {
            if (_serviceBusToIndexSenderClient == null)
            {
               _serviceBusToIndexSenderClient = new ServiceBusHelper(sblogger).CreateServiceBusSender(ServiceBusNameSpaceName, ToIndexQueueName);
            }
            return _serviceBusToIndexSenderClient;
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
                  var intelClient = new DocumentIntelligenceClient(new Uri(Endpoint), credential);
                  _docIntelClients.Add(new() { DocumentIntelligenceClient = intelClient, Endpoint = Settings.Endpoint, Key = key, Index = index });
                  index++;
               }
            }
            return _docIntelClients;
         }
      }
   }
}
