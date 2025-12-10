using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.DocumentIntelligenceFunction
{
   public class DocIntelligenceWorker : ServiceBusWorker
   {
      private readonly DocIntelligence docIntelligence;
      private readonly ILogger<DocIntelligenceWorker> logger;

      public DocIntelligenceWorker(ServiceBusHelper serviceBusHelper, Settings settings, DocIntelligence docIntelligence, ILogger<DocIntelligenceWorker> logger)
          : base(serviceBusHelper, new ServiceBusWorkerOptions(settings.DocumentQueueName), logger)
      {
         this.logger = logger ?? throw new ArgumentNullException(nameof(logger));
         this.logger.LogInformation("Initializing DocIntelligenceWorker for Queue: {QueueName}", settings.DocumentQueueName);
         this.docIntelligence = docIntelligence ?? throw new ArgumentNullException(nameof(docIntelligence));
      }

      protected override async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var fileMessage = args.Message.As<FileQueueMessage>();
         await docIntelligence.ProcessMessageAsync(fileMessage);
      }
   }
}
