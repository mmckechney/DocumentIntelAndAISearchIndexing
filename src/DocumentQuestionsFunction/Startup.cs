using HighVolumeProcessing.DocumentQuestionsFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
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
builder.Services.AddSingleton<AiSearchHelper>();
builder.Services.AddSingleton<Helper>();
builder.Services.AddSingleton<StorageHelper>();
builder.Services.AddSingleton<ServiceBusHelper>();
builder.Services.AddSingleton<Settings>();
builder.Services.AddSingleton<AskQuestions>();
builder.Services.AddHttpClient();
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

app.MapDefaultEndpoints();

app.MapGet("/", () => Results.Ok("Document questions worker is running"));

app.MapMethods("/api/AskQuestions", new[] { HttpMethods.Get, HttpMethods.Post }, async (HttpRequest request, AskQuestions handler, CancellationToken cancellationToken) =>
{
   return await handler.HandleAsync(request, cancellationToken);
});

app.Run();
