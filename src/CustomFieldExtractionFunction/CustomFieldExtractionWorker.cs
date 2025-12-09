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

      public CustomFieldExtractionWorker(ServiceBusHelper serviceBusHelper, Settings settings, CustomFieldExtraction extraction, ILogger<CustomFieldExtractionWorker> logger)
          : base(serviceBusHelper, new ServiceBusWorkerOptions(settings.CustomFieldQueueName), logger)
      {
         this.extraction = extraction ?? throw new ArgumentNullException(nameof(extraction));
      }

      protected override async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var payload = args.Message.As<FileQueueMessage>();
         await extraction.ProcessMessageAsync(payload);
      }
   }
}
