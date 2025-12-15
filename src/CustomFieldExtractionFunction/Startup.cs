using HighVolumeProcessing.CustomFieldExtractionFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = Host.CreateApplicationBuilder(args);

builder.AddServiceDefaults();

builder.Configuration
   .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
   .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: false)
   .AddJsonFile("local.settings.json", optional: true, reloadOnChange: false)
   .AddEnvironmentVariables();

builder.Logging.SetMinimumLevel(LogLevel.Information);
builder.Logging.AddFilter("System", LogLevel.Warning);
builder.Logging.AddFilter("Microsoft", LogLevel.Warning);

builder.Services.AddSingleton<AgentHelper>();
builder.Services.AddSingleton<StorageHelper>();
builder.Services.AddSingleton<ServiceBusHelper>();
builder.Services.AddSingleton<Settings>();
builder.Services.AddSingleton<Tracker<CustomFieldExtraction>>();
builder.Services.AddSingleton<CosmosDbHelper>();
builder.Services.AddSingleton<CustomFieldExtraction>();
builder.Services.AddHostedService<CustomFieldExtractionWorker>();
builder.Services.AddHttpClient();
builder.Services.AddApplicationInsightsTelemetryWorkerService();

var host = builder.Build();

await host.RunAsync();
