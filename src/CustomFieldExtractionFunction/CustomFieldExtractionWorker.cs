using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.CustomFieldExtractionFunction
{
   public class CustomFieldExtractionWorker : ServiceBusWorker
   {
      private readonly CustomFieldExtraction extraction;
      private readonly ILogger<CustomFieldExtractionWorker> logger;

      public CustomFieldExtractionWorker(ServiceBusHelper serviceBusHelper, Settings settings, CustomFieldExtraction extraction, ILogger<CustomFieldExtractionWorker> logger)
          : base(serviceBusHelper, new ServiceBusWorkerOptions(settings.CustomFieldQueueName), logger)
      {
         this.extraction = extraction ?? throw new ArgumentNullException(nameof(extraction));
         this.logger = logger ?? throw new ArgumentNullException(nameof(logger));
         this.logger.LogInformation("Initializing CustomFieldExtractionWorker for Queue: {QueueName}", settings.CustomFieldQueueName);
      }

      protected override async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var payload = args.Message.As<FileQueueMessage>();
         await extraction.ProcessMessageAsync(payload);
      }
   }
}
