using Microsoft.Extensions.Options;

var builder = DistributedApplication.CreateBuilder(args);

// Configure to skip DCP orchestration for local development
// Services will need to be run individually
// builder.Services.Configure<DistributedApplicationOptions>(options =>
// {
//     options.DisableOrchestrator = true;
// });

// Azure Resources
var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator();

var blobs = storage.AddBlobs("blobs");

var serviceBus = builder.AddAzureServiceBus("servicebus")
    .RunAsEmulator();

var cosmos = builder.AddAzureCosmosDB("cosmos")
    .RunAsEmulator();

var cosmosDb = cosmos.AddCosmosDatabase("cosmosdb");

var aiSearch = builder.AddAzureSearch("aisearch");

var insights = builder.AddAzureApplicationInsights("insights");

// Note: For local development, you may need to provide connection strings
// for Document Intelligence and other services that don't have emulators

// Container Apps - Function services  
// Using executable references instead of Projects namespace
var queueingAppPath = Path.Combine(builder.AppHostDirectory, "..", "DocumentQueueingFunction", "DocumentQueueingFunction.csproj");
var intelligenceAppPath = Path.Combine(builder.AppHostDirectory, "..", "DocumentIntelligenceFunction", "DocumentIntelligenceFunction.csproj");
var customFieldAppPath = Path.Combine(builder.AppHostDirectory, "..", "CustomFieldExtractionFunction", "CustomFieldExtractionFunction.csproj");
var aiSearchAppPath = Path.Combine(builder.AppHostDirectory, "..", "AiSearchIndexingFunction", "AiSearchIndexingFunction.csproj");
var questionsAppPath = Path.Combine(builder.AppHostDirectory, "..", "DocumentQuestionsFunction", "DocumentQuestionsFunction.csproj");
var moverAppPath = Path.Combine(builder.AppHostDirectory, "..", "ProcessedFileMover", "ProcessedFileMover.csproj");

builder.AddProject("queueing-app", queueingAppPath)
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithReference(insights);

builder.AddProject("intelligence-app", intelligenceAppPath)
    .WithReference(serviceBus)
    .WithReference(insights);

builder.AddProject("custom-field-app", customFieldAppPath)
    .WithReference(serviceBus)
    .WithReference(cosmosDb)
    .WithReference(insights);

builder.AddProject("aisearch-app", aiSearchAppPath)
    .WithReference(serviceBus)
    .WithReference(aiSearch)
    .WithReference(cosmosDb)
    .WithReference(insights);

builder.AddProject("askquestions-app", questionsAppPath)
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithReference(insights);

builder.AddProject("mover-app", moverAppPath)
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithReference(insights);

builder.Build().Run();
