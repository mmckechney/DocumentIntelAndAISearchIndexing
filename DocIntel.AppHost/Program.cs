using Aspire.Hosting;

Environment.SetEnvironmentVariable("ASPNETCORE_URLS", "http://localhost:5000");
Environment.SetEnvironmentVariable("DOTNET_DASHBOARD_OTLP_ENDPOINT_URL", "http://localhost:4317");
Environment.SetEnvironmentVariable("DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL", "http://localhost:4318");
Environment.SetEnvironmentVariable("ASPIRE_ALLOW_UNSECURED_TRANSPORT", "true");

var builder = DistributedApplication.CreateBuilder(args);

// Add Azure AI services
var aiSearch = builder.AddAzureSearch("aisearch");
var openAI = builder.AddAzureOpenAI("openai");
//var docIntel = builder.AddAzureDocumentIntelligence("docIntelligence");

// Add storage services
var blobs = builder.AddAzureStorage("storage").AddBlobs("blobs");
var cosmos = builder.AddAzureCosmosDB("cosmos");
var serviceBus = builder.AddAzureServiceBus("servicebus");

// Add application components
var aiSearchIndexingFunction = builder.AddProject<Projects.AiSearchIndexingFunction>("aisearch-indexing")
      .WithReference(aiSearch)
      .WaitFor(aiSearch)
      .WithReference(cosmos)
      .WaitFor(cosmos)
      .WithReference(serviceBus)
      .WaitFor(serviceBus)
      .WithReference(blobs)
      .WaitFor(blobs);


var customFieldExtractionFunction = builder.AddProject<Projects.CustomFieldExtractionFunction>("customfield-extraction")
      .WithReference(openAI)
      .WaitFor(openAI)
      .WithReference(cosmos)
      .WaitFor(cosmos)
      .WithReference(serviceBus)
      .WaitFor(serviceBus)
      .WithReference(blobs)
      .WaitFor(blobs);

var documentIntelligenceFunction = builder.AddProject<Projects.DocumentIntelligenceFunction>("doc-intelligence")
      //.WithReference(docIntel)
      //.waitFor(docIntel)
      .WithReference(cosmos)
      .WaitFor(cosmos)
      .WithReference(serviceBus)
      .WaitFor(serviceBus)
      .WithReference(blobs)
      .WaitFor(blobs);

var documentQuestionsFunction = builder.AddProject<Projects.DocumentQuestionsFunction>("doc-questions")
      .WithReference(openAI)
      .WaitFor(openAI)
      .WithReference(aiSearch)
      .WaitFor(aiSearch)
      .WithReference(cosmos)
      .WaitFor(cosmos);

var documentQueueingFunction = builder.AddProject<Projects.DocumentQueueingFunction>("doc-queueing")
      .WithReference(serviceBus)
      .WaitFor(serviceBus)
      .WithReference(blobs)
      .WaitFor(blobs);

var processedFileMover = builder.AddProject<Projects.ProcessedFileMover>("file-mover")
      .WithReference(cosmos)
      .WaitFor(cosmos)
      .WithReference(serviceBus)
      .WaitFor(serviceBus)
      .WithReference(blobs)
      .WaitFor(blobs);

// Build and run the application
await builder.Build().RunAsync();