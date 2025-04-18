FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["DocumentQueueingFunction/DocumentQueueingFunction.csproj", "DocumentQueueingFunction/"]
COPY ["AzureUtilities/UtilityLibrary.csproj", "AzureUtilities/"]

# Restore dependencies
RUN dotnet restore "DocumentQueueingFunction/DocumentQueueingFunction.csproj"

# Copy all the source code and build
COPY ["DocumentQueueingFunction/", "DocumentQueueingFunction/"]
COPY ["AzureUtilities/", "AzureUtilities/"]
RUN dotnet build "DocumentQueueingFunction/DocumentQueueingFunction.csproj" -c Release -o /app/build  /p:NoWarn="SKEXP*" /p:SuppressExperimentalDiagnostics="SKEXP*" /p:WarnAsError=""

# Publish the app
FROM build AS publish
RUN dotnet publish "DocumentQueueingFunction/DocumentQueueingFunction.csproj" -c Release -o /app/publish /p:UseAppHost=false /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*" /p:WarnAsError=""

# Final image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=publish /app/publish .


ENTRYPOINT ["dotnet", "DocumentQueueingFunction.dll"]