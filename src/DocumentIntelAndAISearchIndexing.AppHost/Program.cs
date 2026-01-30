using Aspire.Hosting;
using Aspire.Hosting.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;

var builder = DistributedApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("local.settings.json", optional: true);

// Define parameters for Azure resource names - values come from configuration
var appInsightsNameParam = builder.AddParameter("appInsightsName", builder.Configuration["APPINSIGHTS_NAME"] ?? "");
var azureAiSearchNameParam = builder.AddParameter("azureAiSearchName", builder.Configuration["AZURE_AISEARCH_NAME"] ?? "");
var cosmosAccountNameParam = builder.AddParameter("cosmosAccountName", builder.Configuration["COSMOS_ACCOUNT_NAME"] ?? "");
var serviceBusNamespaceNameParam = builder.AddParameter("serviceBusNamespaceName", builder.Configuration["SERVICEBUS_NAMESPACE_NAME"] ?? "");
var storageAccountNameParam = builder.AddParameter("storageAccountName", builder.Configuration["STORAGE_ACCOUNT_NAME"] ?? "");
var resourceGroupParam = builder.AddParameter("resourceGroup", builder.Configuration["RESOURCE_GROUP"] ?? "");
// Configure to skip DCP orchestration for local development
// Services will need to be run individually
// builder.Services.Configure<DistributedApplicationOptions>(options =>
// {
//     options.DisableOrchestrator = true;
// });

// Azure Resources
// Use the parameters defined above for Azure resources
var storage = builder.AddAzureStorage("storage").AsExisting(storageAccountNameParam, resourceGroupParam);
var blobs = storage.AddBlobs("blobs");

var serviceBus = builder.AddAzureServiceBus("servicebus").AsExisting(serviceBusNamespaceNameParam, resourceGroupParam);

var cosmos = builder.AddAzureCosmosDB("cosmos").AsExisting(cosmosAccountNameParam, resourceGroupParam);
var cosmosDb = cosmos.AddCosmosDatabase("cosmosdb");

var aiSearch = builder.AddAzureSearch("aisearch").AsExisting(azureAiSearchNameParam, resourceGroupParam);

var insights = builder.AddAzureApplicationInsights("insights").AsExisting(appInsightsNameParam, resourceGroupParam);

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
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithReference(insights);

builder.AddProject("custom-field-app", customFieldAppPath)
    .WithReference(blobs)
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
