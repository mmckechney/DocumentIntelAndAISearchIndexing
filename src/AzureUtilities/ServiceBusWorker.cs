using System;
using System.Threading;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.UtilityLibrary
{
   public abstract class ServiceBusWorker : BackgroundService
   {
      private readonly ServiceBusProcessor processor;
      private readonly ILogger logger;
      private readonly bool autoCompleteMessages;

      protected ServiceBusWorker(ServiceBusHelper serviceBusHelper, ServiceBusWorkerOptions options, ILogger logger)
      {
         serviceBusHelper = serviceBusHelper ?? throw new ArgumentNullException(nameof(serviceBusHelper));
         options = options ?? throw new ArgumentNullException(nameof(options));
         this.logger = logger ?? throw new ArgumentNullException(nameof(logger));

         processor = serviceBusHelper.CreateProcessor(options.QueueName, options.ProcessorOptions);
         autoCompleteMessages = options.ProcessorOptions.AutoCompleteMessages;
      }

      public override async Task StartAsync(CancellationToken cancellationToken)
      {
         processor.ProcessMessageAsync += HandleMessageAsync;
         processor.ProcessErrorAsync += HandleErrorAsync;
         await processor.StartProcessingAsync(cancellationToken);
         await base.StartAsync(cancellationToken);
      }

      public override async Task StopAsync(CancellationToken cancellationToken)
      {
         await processor.StopProcessingAsync(cancellationToken);
         await processor.DisposeAsync();
         await base.StopAsync(cancellationToken);
      }

      protected override Task ExecuteAsync(CancellationToken stoppingToken)
      {
         return Task.CompletedTask;
      }

      private async Task HandleMessageAsync(ProcessMessageEventArgs args)
      {
         try
         {
            await ProcessMessageAsync(args);
            if (!autoCompleteMessages)
            {
               await args.CompleteMessageAsync(args.Message);
            }
         }
         catch (Exception ex)
         {
            logger.LogError(ex, "Error processing Service Bus message");
            await args.AbandonMessageAsync(args.Message);
         }
      }

      private Task HandleErrorAsync(ProcessErrorEventArgs args)
      {
         logger.LogError(args.Exception, "Service Bus processor error. Entity {EntityPath}, namespace {FullyQualifiedNamespace}", args.EntityPath, args.FullyQualifiedNamespace);
         return Task.CompletedTask;
      }

      protected abstract Task ProcessMessageAsync(ProcessMessageEventArgs args);
   }
}
