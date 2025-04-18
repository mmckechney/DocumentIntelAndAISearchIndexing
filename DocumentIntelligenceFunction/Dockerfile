FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["DocumentIntelligenceFunction/DocumentIntelligenceFunction.csproj", "DocumentIntelligenceFunction/"]
COPY ["AzureUtilities/UtilityLibrary.csproj", "AzureUtilities/"]

# Restore dependencies
RUN dotnet restore "DocumentIntelligenceFunction/DocumentIntelligenceFunction.csproj"

# Copy all the source code and build
COPY ["DocumentIntelligenceFunction/", "DocumentIntelligenceFunction/"]
COPY ["AzureUtilities/", "AzureUtilities/"]
RUN dotnet build "DocumentIntelligenceFunction/DocumentIntelligenceFunction.csproj" -c Release -o /app/build  /p:NoWarn="SKEXP*"   /p:SuppressExperimentalDiagnostics="SKEXP*"

# Publish the app
FROM build AS publish
RUN dotnet publish "DocumentIntelligenceFunction/DocumentIntelligenceFunction.csproj" -c Release -o /app/publish /p:UseAppHost=false  /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*"
 
# Final image
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=publish /app/publish .


ENTRYPOINT ["dotnet", "DocumentIntelligenceFunction.dll"]