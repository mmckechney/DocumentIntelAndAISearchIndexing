using System;
using Azure.Messaging.ServiceBus;

namespace HighVolumeProcessing.UtilityLibrary
{
   public class ServiceBusWorkerOptions
   {
      public ServiceBusWorkerOptions(string queueName, ServiceBusProcessorOptions? processorOptions = null)
      {
         QueueName = queueName ?? throw new ArgumentNullException(nameof(queueName));
         ProcessorOptions = processorOptions ?? new ServiceBusProcessorOptions()
         {
            AutoCompleteMessages = false,
            MaxConcurrentCalls = 1
         };
      }

      public string QueueName { get; }

      public ServiceBusProcessorOptions ProcessorOptions { get; }
   }
}
