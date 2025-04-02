using HighVolumeProcessing.UtilityLibrary; 
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace HighVolumeProcessing.DocumentIntelligenceFunction
{
   internal class Startup
   {
      static async Task Main(string[] args)
      {
         string basePath = IsDevelopmentEnvironment() ?
             Environment.GetEnvironmentVariable("AzureWebJobsScriptRoot") :
             $"{Environment.GetEnvironmentVariable("HOME")}\\site\\wwwroot";

         var builder = new HostBuilder();
         builder.ConfigureLogging((hostContext, logging) =>
         {
            logging.SetMinimumLevel(LogLevel.Debug);
            logging.AddFilter("System", LogLevel.Warning);
            logging.AddFilter("Microsoft", LogLevel.Warning);
         });
         
         builder.ConfigureFunctionsWorkerDefaults();
         
         // Add Aspire service defaults
         builder.ConfigureServices(services => 
         {
             var hostBuilder = builder as IHostApplicationBuilder;
             hostBuilder.AddServiceDefaults();
         });
         
         builder.ConfigureAppConfiguration(b =>
         {
            b.SetBasePath(basePath)
              .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)  // common settings go here.
              .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT")}.json", optional: true, reloadOnChange: false)  // environment specific settings go here
              .AddJsonFile("local.settings.json", optional: true, reloadOnChange: false)  // secrets go here. This file is excluded from source control.
              .AddEnvironmentVariables()
              .Build();
         });

         builder.ConfigureServices(ConfigureServices);

         await builder.Build().RunAsync();
      }

      private static void ConfigureServices(HostBuilderContext context, IServiceCollection services)
      {
         var hostBuilder = context.HostingEnvironment as IHostApplicationBuilder;
         // Add Azure services via Aspire
         //TODO: Add document intelligence
         //hostBuilder.AddDocumentIntelligenceClient("docIntelligence");
         hostBuilder.AddAzureBlobClient("blobs");
         hostBuilder.AddAzureCosmosClient("cosmos");
         hostBuilder.AddAzureServiceBusClient("servicebus");
         
         // Add application services
         services.AddSingleton<SkHelper>();
         services.AddSingleton<StorageHelper>();
         services.AddSingleton<ServiceBusHelper>();
         services.AddSingleton<Settings>();
         services.AddSingleton<Tracker<DocIntelligence>>();
         services.AddSingleton<CosmosDbHelper>();
         services.AddHttpClient();
         services.AddApplicationInsightsTelemetryWorkerService();
         services.ConfigureFunctionsApplicationInsights();
      }

      public static bool IsDevelopmentEnvironment()
      {
         return "Development".Equals(Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT"), StringComparison.OrdinalIgnoreCase);
      }
   }
}