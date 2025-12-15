using HighVolumeProcessing.DocumentQueueingFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Configuration
   .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
   .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: false)
   .AddJsonFile("local.settings.json", optional: true, reloadOnChange: false)
   .AddEnvironmentVariables();

builder.Logging
   .AddFilter("System", LogLevel.Warning)
   .AddFilter("Microsoft", LogLevel.Warning)
   .SetMinimumLevel(LogLevel.Information);

builder.Services.AddSingleton<AgentHelper>();
builder.Services.AddSingleton<StorageHelper>();
builder.Services.AddSingleton<ServiceBusHelper>();
builder.Services.AddSingleton<Settings>();
builder.Services.AddSingleton<Tracker<DocumentQueueing>>();
builder.Services.AddSingleton<CosmosDbHelper>();
builder.Services.AddSingleton<DocumentQueueing>();
builder.Services.AddHttpClient();
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

app.MapDefaultEndpoints();

app.MapGet("/", () => Results.Ok("Document queueing worker is running"));

app.MapGet("/api/DocumentQueueing", async (bool? force, DateTime? queuedDate, DocumentQueueing queueing, CancellationToken cancellationToken) =>
{
   var queuedCount = await queueing.QueueDocumentsAsync(force ?? false, queuedDate, cancellationToken);
   return Results.Ok(new { queued = queuedCount });
});

app.MapGet("/queue", async (bool? force, DateTime? queuedDate, DocumentQueueing queueing, CancellationToken cancellationToken) =>
{
   var queuedCount = await queueing.QueueDocumentsAsync(force ?? false, queuedDate, cancellationToken);
   return Results.Ok(new { queued = queuedCount });
});

app.Run();