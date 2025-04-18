FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy project files
COPY ["AiSearchIndexingFunction/AiSearchIndexingFunction.csproj", "AiSearchIndexingFunction/"]
COPY ["AzureUtilities/UtilityLibrary.csproj", "AzureUtilities/"]

# Restore dependencies
RUN dotnet restore "AiSearchIndexingFunction/AiSearchIndexingFunction.csproj"

# Copy all the source code and build
COPY ["AiSearchIndexingFunction/", "AiSearchIndexingFunction/"]
COPY ["AzureUtilities/", "AzureUtilities/"]
RUN dotnet build "AiSearchIndexingFunction/AiSearchIndexingFunction.csproj" -c Release -f net8.0  -o /app/build   

# Publish the app
FROM build AS publish
RUN dotnet publish "AiSearchIndexingFunction/AiSearchIndexingFunction.csproj" -c Release -f net8.0  -o /app/publish --self-contained

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

# Final image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "AiSearchIndexingFunction.dll"]