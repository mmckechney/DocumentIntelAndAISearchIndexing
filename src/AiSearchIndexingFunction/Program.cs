using HighVolumeProcessing.AiSearchIndexingFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = Host.CreateDefaultBuilder(args)
   .ConfigureAppConfiguration((context, config) =>
   {
      config
         .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
         .AddJsonFile($"appsettings.{context.HostingEnvironment.EnvironmentName}.json", optional: true, reloadOnChange: false)
         .AddJsonFile("local.settings.json", optional: true, reloadOnChange: false)
         .AddEnvironmentVariables();
   })
   .ConfigureLogging(logging =>
   {
      logging.SetMinimumLevel(LogLevel.Information);
      logging.AddFilter("System", LogLevel.Warning);
      logging.AddFilter("Microsoft", LogLevel.Warning);
   })
   .ConfigureServices((context, services) =>
   {
      services.AddSingleton<SkHelper>();
      services.AddSingleton<AiSearchHelper>();
      services.AddSingleton<StorageHelper>();
      services.AddSingleton<ServiceBusHelper>();
      services.AddSingleton<Settings>();
      services.AddSingleton<Tracker<AiSearchIndexing>>();
      services.AddSingleton<CosmosDbHelper>();
      services.AddSingleton<AiSearchIndexing>();
      services.AddHostedService<AiSearchIndexingWorker>();
      services.AddHttpClient();
      services.AddApplicationInsightsTelemetryWorkerService();
   });

await builder.RunConsoleAsync();
