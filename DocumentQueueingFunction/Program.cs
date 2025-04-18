using HighVolumeProcessing.DocumentQueueingFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;



var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<SkHelper>();
builder.Services.AddSingleton<StorageHelper>();
builder.Services.AddSingleton<ServiceBusHelper>();
builder.Services.AddSingleton<Settings>();
builder.Services.AddSingleton<Tracker<DocumentQueueing>>();
builder.Services.AddSingleton<CosmosDbHelper>();
builder.Services.AddHealthChecks(); 


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
   app.UseSwagger();
   app.UseSwaggerUI();
}
app.MapHealthChecks("/health");
app.MapGet("/", async (HttpRequest request, DocumentQueueing docQueuing) =>
{

   bool.TryParse(request.Query["force"], out bool force);
   DateTime.TryParse(request.Query["fromDate"], out DateTime fromDate);
   (string message, var code) = await docQueuing.QueueDocs(force, fromDate);

   if (code == System.Net.HttpStatusCode.OK)
   {
      app.Logger.LogInformation($"Request completed successfully. {message}");
      return Results.Ok(message);
   }
   else
   {
      app.Logger.LogError($"Request failed. {message}");
      return Results.Problem(message);
   }

});

app.Run();
