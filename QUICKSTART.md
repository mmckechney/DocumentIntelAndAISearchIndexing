# Quick Start: Running with .NET Aspire

## Prerequisites
- .NET 10.0 SDK
- Docker Desktop (for Azure emulators)
- Visual Studio 2022 with ".NET Aspire SDK" component (recommended for local development)

## Running the Solution

### Method 1: Visual Studio (Recommended)
1. Open `src/DocumentIntelAndAISearchIndexing.sln` in Visual Studio 2022
2. Right-click on `DocumentIntelAndAISearchIndexing.AppHost` project → Set as Startup Project
3. Press **F5** or click the Start button
4. The Aspire Dashboard will automatically open in your browser
5. All services will start, and you'll see them in the dashboard

### Method 2: Command Line
```bash
cd src/DocumentIntelAndAISearchIndexing.AppHost
dotnet run
```

Then navigate to: `https://localhost:17164` to see the Aspire Dashboard

## What You'll See

### Aspire Dashboard Features:
- **Resources Tab**: View all running services and their status
- **Console Logs Tab**: Real-time logs from all services
- **Structured Logs Tab**: Query and filter logs with structured data
- **Traces Tab**: Distributed tracing across services
- **Metrics Tab**: Performance metrics and counters

### Services That Will Start:
1. **queueing-app** (DocumentQueueingFunction) - HTTP endpoint on assigned port
2. **intelligence-app** (DocumentIntelligenceFunction) - Background worker
3. **custom-field-app** (CustomFieldExtractionFunction) - Background worker
4. **aisearch-app** (AiSearchIndexingFunction) - Background worker
5. **askquestions-app** (DocumentQuestionsFunction) - HTTP endpoint on assigned port
6. **mover-app** (ProcessedFileMover) - Background worker

### Azure Resource Emulators:
- **Azurite** (Azure Storage emulator) - Automatically started
- **Service Bus Emulator** - May need configuration
- **Cosmos DB Emulator** - May need to be installed and running

## Testing the Services

### Queue Documents (DocumentQueueingFunction)
```bash
# Find the port in Aspire Dashboard under "queueing-app"
curl http://localhost:<PORT>/api/DocumentQueueing
```

### Ask Questions (DocumentQuestionsFunction)
```bash
# Find the port in Aspire Dashboard under "askquestions-app"
curl http://localhost:<PORT>/api/AskQuestions
```

## Configuration

### Local Settings
Each service reads configuration from:
1. `appsettings.json`
2. `local.settings.json` (create if missing)
3. Environment variables
4. Aspire-provided connection strings (automatically injected)

### Example local.settings.json:
```json
{
  "Values": {
    "AZURE_STORAGE_ACCOUNT_NAME": "devstoreaccount1",
    "AZURE_STORAGE_CONNECTION_STRING": "UseDevelopmentStorage=true"
  }
}
```

## Stopping the Application

- **Visual Studio**: Click Stop or press Shift+F5
- **Command Line**: Press Ctrl+C

All services and emulators will shut down gracefully.

## Troubleshooting

### Port Already in Use
The Aspire Dashboard runs on port 17164 by default. If this port is in use:
1. Edit `src/DocumentIntelAndAISearchIndexing.AppHost/Properties/launchSettings.json`
2. Change the port in the `applicationUrl` setting

### Azure Emulator Not Starting
- Ensure Docker Desktop is running
- For Cosmos DB Emulator, you may need to install it separately:
  ```bash
  winget install Microsoft.Azure.CosmosEmulator
  ```

### Service Won't Start
Check the Console Logs tab in the Aspire Dashboard for detailed error messages.

## Deploying to Azure

The Aspire changes **do not affect** your Azure deployment. Continue using:
```bash
azd up          # First time or full deployment
azd deploy      # Code-only deployment
```

## Next Steps

- Explore the **Traces** tab to see how requests flow between services
- View **Metrics** to monitor performance
- Use **Structured Logs** to debug issues with advanced filtering
- Check out `ASPIRE-README.md` for more detailed information

## Learn More

- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire)
- [Aspire Dashboard Overview](https://learn.microsoft.com/dotnet/aspire/fundamentals/dashboard)
- [OpenTelemetry in .NET](https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel)
