using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.AiSearchIndexingFunction
{
   public class AiSearchIndexingWorker : ServiceBusWorker
   {
      private readonly AiSearchIndexing indexing;

      public AiSearchIndexingWorker(ServiceBusHelper serviceBusHelper, Settings settings, AiSearchIndexing indexing, ILogger<AiSearchIndexingWorker> logger)
         : base(serviceBusHelper, new ServiceBusWorkerOptions(settings.ToIndexQueueName), logger)
      {
         this.indexing = indexing ?? throw new ArgumentNullException(nameof(indexing));
      }

      protected override async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var payload = args.Message.As<FileQueueMessage>();
         await indexing.ProcessMessageAsync(payload);
      }
   }
}
