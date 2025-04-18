using HighVolumeProcessing.DocumentQuestionsFunction;
using HighVolumeProcessing.UtilityLibrary;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<SkHelper>();
builder.Services.AddSingleton<AiSearchHelper>();
builder.Services.AddSingleton<StorageHelper>();
builder.Services.AddSingleton<ServiceBusHelper>();
builder.Services.AddSingleton<Settings>();
builder.Services.AddHealthChecks();

builder.Logging.AddConsole();
builder.Configuration.AddJsonFile("appsettings.json", optional: true, reloadOnChange: false);  // common settings go here.
builder.Configuration.AddJsonFile("local.settings.json", optional: true, reloadOnChange: false);
builder.Configuration.AddEnvironmentVariables();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
   app.UseSwagger();
   app.UseSwaggerUI();
}
app.MapHealthChecks("/health");
app.MapGet("/", async (HttpRequest request, QuestionModel questionData, AskQuestions docQuestions) =>
{

   (string message, var code) = await docQuestions.Question(questionData.question, questionData.customField, questionData.fileName);

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


