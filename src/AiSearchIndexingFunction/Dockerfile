# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source
COPY src/ ./src/
RUN dotnet restore src/AiSearchIndexingFunction/AiSearchIndexingFunction.csproj
RUN dotnet publish src/AiSearchIndexingFunction/AiSearchIndexingFunction.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV COMPlus_EnableDiagnostics=0
ENTRYPOINT ["dotnet", "AiSearchIndexingFunction.dll"]
