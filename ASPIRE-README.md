# .NET Aspire Integration

This solution has been updated to use .NET Aspire for orchestration, observability, and cloud-native development.

## What's New

### Aspire Projects

1. **DocumentIntelAndAISearchIndexing.AppHost** - Orchestrates all services and their dependencies
   - Manages Azure resource connections
   - Provides service discovery
   - Configures telemetry and observability

2. **DocumentIntelAndAISearchIndexing.ServiceDefaults** - Shared configuration library
   - OpenTelemetry integration for tracing and metrics
   - Health checks
   - Resilience patterns
   - Service discovery

### Updated Services

All six function projects now reference ServiceDefaults and include:
- Standardized telemetry and logging
- Health check endpoints (in development mode)
- Resilient HTTP clients
- Service discovery capabilities

## Running Locally with Aspire

### Prerequisites
- .NET 9.0 SDK or later
- Docker Desktop (for Azure resource emulators)

### Start the Solution

1. **Using Visual Studio 2022:**
   - Open the solution
   - Set `DocumentIntelAndAISearchIndexing.AppHost` as the startup project
   - Press F5 to run

2. **Using the .NET CLI:**
   ```bash
   cd src/DocumentIntelAndAISearchIndexing.AppHost
   dotnet run
   ```

3. **Access the Aspire Dashboard:**
   - The dashboard will open automatically at `https://localhost:17164`
   - View all services, traces, metrics, and logs in one place

### Aspire Dashboard Features

The dashboard provides:
- **Resources**: View all running services and Azure resources
- **Console Logs**: See logs from all services in real-time
- **Structured Logs**: Query and filter structured logs
- **Traces**: Distributed tracing across services
- **Metrics**: Performance metrics and counters

## Deploying to Azure

The existing Azure deployment process continues to work with `azd`:

```bash
# Provision and deploy
azd up

# Deploy only
azd deploy

# Provision only
azd provision
```

Aspire enhances the local development experience while maintaining compatibility with your existing Azure infrastructure defined in the `infra/` directory.

## Azure Resource Emulators

When running locally, Aspire automatically starts emulators for:
- Azure Storage (via Azurite)
- Azure Service Bus (via Azure Service Bus Emulator)
- Azure Cosmos DB (via Cosmos DB Emulator)

These emulators allow full local development without connecting to Azure resources.

## Configuration

Services automatically receive configuration from:
1. `appsettings.json`
2. `local.settings.json`
3. Environment variables
4. Aspire-provided service connections

## Service Architecture

```
AppHost
├── Azure Resources
│   ├── Storage (with Blobs)
│   ├── Service Bus
│   ├── Cosmos DB
│   ├── AI Search
│   ├── Document Intelligence
│   └── Application Insights
└── Services
    ├── queueing-app
    ├── intelligence-app
    ├── custom-field-app
    ├── aisearch-app
    ├── askquestions-app
    └── mover-app
```

Each service has explicit dependencies on the Azure resources it needs, managed by Aspire.

## Learn More

- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire)
- [Aspire Dashboard](https://learn.microsoft.com/dotnet/aspire/fundamentals/dashboard)
- [Service Defaults](https://learn.microsoft.com/dotnet/aspire/fundamentals/service-defaults)
