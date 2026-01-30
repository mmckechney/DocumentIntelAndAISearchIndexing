# .NET Aspire Local Development Setup

## Issue: DCP Not Found

When running `dotnet run` on the AppHost project, you may encounter:
```
Property CliPath: The path to the DCP executable used for Aspire orchestration is required.
Property DashboardPath: The path to the Aspire Dashboard binaries is missing.
```

## Root Cause

.NET Aspire requires the **Developer Control Plane (DCP)** for local orchestration. In .NET 10, the Aspire workload has been deprecated in favor of NuGet packages, but DCP is still required for running the AppHost locally.

## Solutions

### Option 1: Install Visual Studio 2022 Aspire Components (Recommended)

Install Visual Studio 2022 with the ".NET Aspire SDK" component:
1. Open Visual Studio Installer
2. Modify your Visual Studio 2022 installation
3. Under "Individual components", search for ".NET Aspire"
4. Check ".NET Aspire SDK"  
5. Click "Modify" to install

This installs DCP and allows you to run the AppHost with F5 in Visual Studio.

### Option 2: Run Services Individually (No Orchestration)

All function projects have been updated with ServiceDefaults and can run independently:

```powershell
# Terminal 1
cd src\DocumentQueueingFunction
dotnet run

# Terminal 2  
cd src\DocumentIntelligenceFunction
dotnet run

# Terminal 3
cd src\CustomFieldExtractionFunction
dotnet run

# etc...
```

Each service will still benefit from:
- ✅ OpenTelemetry tracing
- ✅ Health checks
- ✅ Resilience patterns  
- ✅ Service defaults configuration

You just won't have the centralized Dashboard or automatic resource emulators.

### Option 3: Use Manifest for Deployment

Generate a deployment manifest without running locally:

```powershell
cd src\DocumentIntelAndAISearchIndexing.AppHost
dotnet run --publisher manifest --output-path .\aspire-manifest.json
```

This manifest can be used with:
- `azd deploy` for Azure deployment
- Docker Compose generation
- Kubernetes manifest generation
- Other deployment tools

## Verification

To verify Aspire is working without DCP:

```powershell
# Build solution (should succeed)
dotnet build

# Generate manifest (should succeed)  
cd src\DocumentIntelAndAISearchIndexing.AppHost
dotnet run --publisher manifest --output-path .\manifest.json

# Check manifest was created
dir manifest.json
```

## What Works Without DCP

✅ **Code Integration**: All Aspire patterns are in your code  
✅ **Service Defaults**: OpenTelemetry, health checks, resilience  
✅ **Build System**: Solution builds successfully  
✅ **Deployment**: `azd up` still works for Azure  
✅ **Manifest Generation**: Can generate deployment artifacts  

❌ **Local Dashboard**: Requires DCP for visual monitoring  
❌ **Automatic Emulators**: Storage/ServiceBus/Cosmos emulators require DCP  
❌ **Orchestration**: Centralized service lifecycle management requires DCP  

## Azure Deployment (No DCP Required)

Deploying to Azure works perfectly without DCP:

```powershell
azd up
```

The Aspire integration enhances the Azure deployment with:
- Automatic container building
- Service-to-service connections
- Resource provisioning via manifest
- Infrastructure as code generation

## Additional Resources

- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [Aspire Support Policy](https://aka.ms/aspire/support-policy)  
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
