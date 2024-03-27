using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
namespace AzureUtilities
{
   public class ServiceBusHelper
   {
      private readonly ILogger<ServiceBusHelper> logger;
      public ServiceBusHelper(ILogger<ServiceBusHelper> logger)
      {
         this.logger = logger;

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
