FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["DocumentQuestionsFunction/DocumentQuestionsFunction.csproj", "DocumentQuestionsFunction/"]
COPY ["AzureUtilities/UtilityLibrary.csproj", "AzureUtilities/"]

# Restore dependencies
RUN dotnet restore "DocumentQuestionsFunction/DocumentQuestionsFunction.csproj"

# Copy all the source code and build
COPY ["DocumentQuestionsFunction/", "DocumentQuestionsFunction/"]
COPY ["AzureUtilities/", "AzureUtilities/"]
RUN dotnet build "DocumentQuestionsFunction/DocumentQuestionsFunction.csproj" -c Release -o /app/build  /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*"

# Publish the app
FROM build AS publish 
RUN dotnet publish "DocumentQuestionsFunction/DocumentQuestionsFunction.csproj" -c Release -o /app/publish /p:UseAppHost=false  /p:NoWarn="SKEXP*"  /p:SuppressExperimentalDiagnostics="SKEXP*"

# Final image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /home/site/wwwroot
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "DocumentQuestionsFunction.dll"]