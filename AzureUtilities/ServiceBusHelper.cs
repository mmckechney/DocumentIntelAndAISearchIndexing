using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
namespace HighVolumeProcessing.UtilityLibrary
{
   public class ServiceBusHelper
   {
      private readonly ILogger<ServiceBusHelper> logger;
      private Dictionary<string, ServiceBusSender> senders = new();
      Settings settings;
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
      object lockObject = new object();
      private ServiceBusSender GetServiceBusSender(string queueName)
      {
         lock (lockObject)
         {
            if (senders.ContainsKey(queueName))
            {
               return senders[queueName];
            }
            else
            {
               var serviceBusSender = CreateServiceBusSender(settings.ServiceBusNamespaceName, queueName);
               senders.Add(queueName, serviceBusSender);
               return serviceBusSender;
            }
         }
      }

      private ServiceBusClient CreateServiceBusClient(string serviceBusNamespace, string queueName)
      {
         var fullyQualified = $"{serviceBusNamespace}.servicebus.windows.net";
         return new ServiceBusClient(fullyQualified, AadHelper.TokenCredential);
      }

      private ServiceBusSender CreateServiceBusSender(string serviceBusNamespace, string queueName)
      {
         var sbc = CreateServiceBusClient(serviceBusNamespace, queueName);
         return sbc.CreateSender(queueName);
      }
   }
}
