using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
namespace AzureUtilities
{
   public class ServiceBusHelper
   {
      private readonly ILogger<ServiceBusHelper> logger;
      private Dictionary<string, ServiceBusSender> senders = new();
      public ServiceBusHelper(ILogger<ServiceBusHelper> logger)
      {
         this.logger = logger;

      }

      public async Task SendMessageAsync(string queueName,ServiceBusMessage message)
      {
         var sender = GetServiceBusSender(queueName);
         await sender.SendMessageAsync(message);
      }
      public ServiceBusSender GetServiceBusSender(string queueName)
      {
         if (senders.ContainsKey(queueName))
         {
            return senders[queueName];
         }
         else
         {
            var serviceBusSender = CreateServiceBusSender(Settings.ServiceBusNamespaceName, queueName);
            senders.Add(queueName, serviceBusSender);
            return serviceBusSender;
         }
      }

      private ServiceBusClient CreateServiceBusClient(string serviceBusNamespace, string queueName)
      {
         var fullyQualified = $"{serviceBusNamespace}.servicebus.windows.net";
         return new ServiceBusClient(fullyQualified, AadHelper.TokenCredential);
      }

      public ServiceBusSender CreateServiceBusSender(string serviceBusNamespace, string queueName)
      {
         var sbc = CreateServiceBusClient(serviceBusNamespace, queueName);
         return sbc.CreateSender(queueName);
      }
   }
}
