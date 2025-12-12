using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using HighVolumeProcessing.UtilityLibrary;
using HighVolumeProcessing.UtilityLibrary.Models;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.ProcessedFileMover
{
   public class ProcessedFileMoverWorker : ServiceBusWorker
   {
      private readonly FileMover mover;
      private readonly ILogger<ProcessedFileMoverWorker> logger;

      public ProcessedFileMoverWorker(ServiceBusHelper serviceBusHelper, Settings settings, FileMover mover, ILogger<ProcessedFileMoverWorker> logger)
         : base(serviceBusHelper, new ServiceBusWorkerOptions(settings.MoveQueueName), logger)
      {
         this.mover = mover ?? throw new ArgumentNullException(nameof(mover));
         this.logger = logger ?? throw new ArgumentNullException(nameof(logger));
         this.logger.LogInformation("Initializing ProcessedFileMoverWorker for Queue: {QueueName}", settings.MoveQueueName);
      }

      protected override async Task ProcessMessageAsync(ProcessMessageEventArgs args)
      {
         var payload = args.Message.As<FileQueueMessage>();
         await mover.ProcessMessageAsync(payload);
      }
   }
}
