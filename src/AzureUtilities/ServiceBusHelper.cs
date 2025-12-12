using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
namespace HighVolumeProcessing.UtilityLibrary
{
   public class ServiceBusHelper
   {
      private readonly ILogger<ServiceBusHelper> logger;
      private readonly Dictionary<string, ServiceBusSender> senders = new();
      private readonly Settings settings;
      private readonly object lockObject = new();
      private ServiceBusClient? cachedClient;

      public ServiceBusHelper(ILogger<ServiceBusHelper> logger, Settings settings)
      {
         this.logger = logger;
         this.settings = settings;

      }

      public async Task SendMessageAsync(string queueName, ServiceBusMessage message)
      {
         var sender = GetServiceBusSender(queueName);
         logger.LogInformation($"Sending to Queue: '{queueName}'");
         await sender.SendMessageAsync(message);
      }

      public ServiceBusProcessor CreateProcessor(string queueName, ServiceBusProcessorOptions? options = null)
      {
         var client = GetOrCreateClient();
         return client.CreateProcessor(queueName, options ?? new ServiceBusProcessorOptions()
         {
            AutoCompleteMessages = false,
            MaxConcurrentCalls = 1
         });
      }

      private ServiceBusSender GetServiceBusSender(string queueName)
      {
         lock (lockObject)
         {
            if (senders.TryGetValue(queueName, out var existing))
            {
               return existing;
            }

            var serviceBusSender = CreateServiceBusSender(queueName);
            senders.Add(queueName, serviceBusSender);
            return serviceBusSender;
         }
      }

      private ServiceBusClient GetOrCreateClient()
      {
         lock (lockObject)
         {
            if (cachedClient == null)
            {
               cachedClient = CreateServiceBusClient(settings.ServiceBusNamespaceName);
            }

            return cachedClient;
         }
      }

      private ServiceBusClient CreateServiceBusClient(string serviceBusNamespace)
      {
         var fullyQualified = $"{serviceBusNamespace}.servicebus.windows.net";
         return new ServiceBusClient(fullyQualified, AadHelper.TokenCredential);
      }

      private ServiceBusSender CreateServiceBusSender(string queueName)
      {
         var client = GetOrCreateClient();
         return client.CreateSender(queueName);
      }
   }
}
