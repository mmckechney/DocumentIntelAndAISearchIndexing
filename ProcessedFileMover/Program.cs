﻿using HighVolumeProcessing.UtilityLibrary;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace HighVolumeProcessing.ProcessedFileMover
{
   internal class Startup
   {
      static async Task Main(string[] args)
      {
         string basePath = AppContext.BaseDirectory;

         var builder = new HostBuilder();
         builder.ConfigureLogging((hostContext, logging) =>
         {
            logging.SetMinimumLevel(LogLevel.Debug);
            logging.AddFilter("System", LogLevel.Warning);
            logging.AddFilter("Microsoft", LogLevel.Warning);
            logging.AddConsole();

         });
         //builder.ConfigureFunctionsWorkerDefaults();
         builder.ConfigureAppConfiguration(b =>
         {
            b.SetBasePath(basePath)
              .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)  // common settings go here.
              .AddJsonFile("local.settings.json", optional: true, reloadOnChange: false)  // secrets go here. This file is excluded from source control.
              .AddEnvironmentVariables()
              .Build();

         });
         // builder.AddAzureStorage();

         builder.ConfigureServices(ConfigureServices);


         await builder.Build().RunAsync();
      }


      private static void ConfigureServices(HostBuilderContext context, IServiceCollection services)
      {
         services.AddHostedService<FileMover>();
         services.AddSingleton<SkHelper>();
         services.AddSingleton<StorageHelper>();
         services.AddSingleton<ServiceBusHelper>();
         services.AddSingleton<Settings>();
         services.AddSingleton<Tracker<FileMover>>();
         services.AddSingleton<CosmosDbHelper>();
      }


   }
}