FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["CustomFieldExtractionFunction/CustomFieldExtractionFunction.csproj", "CustomFieldExtractionFunction/"]
COPY ["AzureUtilities/UtilityLibrary.csproj", "AzureUtilities/"]

# Restore dependencies
RUN dotnet restore "CustomFieldExtractionFunction/CustomFieldExtractionFunction.csproj"

# Copy all the source code and build
COPY ["CustomFieldExtractionFunction/", "CustomFieldExtractionFunction/"]
COPY ["AzureUtilities/", "AzureUtilities/"]
RUN dotnet build "CustomFieldExtractionFunction/CustomFieldExtractionFunction.csproj" -c Release -o /app/build  /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*"

# Publish the app
FROM build AS publish
RUN dotnet publish "CustomFieldExtractionFunction/CustomFieldExtractionFunction.csproj" -c Release -o /app/publish /p:UseAppHost=false  /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*"

# Final image
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "CustomFieldExtractionFunction.dll"]