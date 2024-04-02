# High Throughput Azure AI Document Intelligence with AI Search Indexing

This repository is offered to demonstrate a set of resources that will allow you to leverage [Azure AI Document Intelligence](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/?view=doc-intel-4.0.0) for high throughput of processing documents stored in Azure Blob Storage to extract text. It then utilized Semantic Kernel, Azure OpenAI and Azure AI Search to index the contents of these documents. The solution can be used to process documents in a variety of formats, including Office documents, PDF, PNG, and JPEG.



**IMPORTANT!** In addition to leveraging the solution below with multiple Document Intelligence instances, it will be beneficial to _request a transaction limit increase_ for your Document Intelligence Accounts. Instructions for how to do this can be found in the [Azure AI Document Intelligence Documentation](https://docs.microsoft.com/en-us/azure/applied-ai-services/form-recognizer/service-limits#increasing-transactions-per-second-request-limit)

## Architecture and Process Overview
![Process flow](Images/ProcessFlow.png)


## Feature Details

This solution leverages the following Azure services:

- **[Azure AI Document Intelligence](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/?view=doc-intel-4.0.0)** - the Azure AI Service API that will perform the document intelligence, extraction and processing.

- **[Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)** - the Azure AI Service API that will perform the semantic embedding calculations of the extracted text.
- **[Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/)** - used to load balance across multiple Azure OpenAI instances
- **[Azure AI Search](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search)** - the Azure AI Service that will index the extracted text for search and analysis.
- **[Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)** with three containers
  - `documents` - starting location to perform your bulk upload of documents to be processed
  - `processresults`  - the extracted text output from the Document Intelligence service
  - `completed` - location where the original documents are moved to once successfully processed by Document Intelligence
- **[Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/)** with three queues
  - `docqueue` - this contains the messages for the files that need to be processed by the Document Intelligence service
  - `toindexqueue` - this contains the messages for the files that have been processed by the Document Intelligence service and the reults are ready to be indexed by Azure AI Search
  - `processedqueue` - this contains the messages for the files that have been processed by the Document Intelligence service and are ready to be moved to the `completed` blob container
- **[Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview?pivots=programming-language-csharp)**
  - `DocumentQueueing` - identifies the files in the `document` blob container and send a claim check message (containing the file name) to the `docqueue` queue. This function is triggered by an HTTP call, but could also be modified to use a Blob Trigger
  - `DocumentIntelligence` - processes the message in `docqueue` to Document Intelligence, then updates Blob metadata as "processed" and create new message in `toindexqueue` and `processedqueue` \
    This function employs scale limiting and [Polly](https://github.com/App-vNext/Polly) retries with back off for Document Intelligence (too many requests) replies to balance maximum throughput and overloading the API endpoint
  - `AiSearcIndexing` - processes messages in the `toindexqueue` to get embeddings of the extracted text from Azure Open AI and saves those embeddings to Azure AI Search
  - `FileMover` - processes messages in the `processedqueue` to move files from `document` to `completed` blob containers

### Multiple Document Intelligence endpoints

To further allow for high throughput, the `DocumentIntelligence` function can distribute processing between 1-10 separate Document Intelligence accounts. This is managed by the `docqueue` funtion automatically adding a `RecognizerIndex` value of 0-9 when queueing the files for processing. 

The DocumentIntelligence function will distribute the files to the appropriate account (regardless of the number of Document Intelligence accounts actually provisioned). 

To configure multiple Document Intelligence accounts with the script below, add a value between 1-10 for the `-docIntelligenceInstanceCount` (default is 1). To configure manually, you will need to add all of the Document Intelligence account keys to the Azure Key Vault's `DOCUMENT-INTELLIGENCE-KEY` secret -- _pipe separated_

_Assumption:_ all instances of the Document Intelligence share the same URL (such as: https://eastus.api.cognitive.microsoft.com/)

### Multiple Azure OpenAI endpoints

In a similar way with Document Intelligence, to ensure high throughput, you can deploy multiple Azure OpenAI accounts. To assist in load balancing, the accounts are front-ended with Azure API Management which handled the load balancing and circuit breaker should an instance get overloaded.


## Get Started

To try out the sample end-to-end process, you will need:

- An Azure subscription that you have privileges to create resources.
- Have the [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

### Running deployment script

1. **IMPORTANT**: Open and edit the `main.bicepparam` file found in the `infra` folder. This file will contain the information needed to properly deploy the API Management and Azure OpenAI accounts:

    - **APIM settings**
      - `apiManagementPublisherEmail` - set this to your email or the email address of the APIM owner
      - `apiManagementPublisherName` - your name or the name of the APIM owner

    - **Azure OpenAI model settings**

      - `azureOpenAIEmbeddingModel` - embedding model you will use to generate the embeddings
      - `embeddingModelVersion` - the version of the embedding model to use
      - `embeddingMaxTokens` - the maximum 'chunk' size you want to used to split up large documents for embedding and indexing. Be sure it does not exceed the limit of the model you have chosen.
      - `azureOpenAIChatModel` - the chat/completions model to use
      - `chatModelVersion` - the versio of the chat model

    - **Azure OpenAI deployment settings**

        For each deployment you want to create, add an object type type as per the example below (note `name` is optional)

        ``` bicep
        var eastUs = {
            name: ''
            location: 'eastus'
            suffix: 'eastus'
        }
        ```

        then, add that object variable to the `openAIInstances` parameter value such as:

        ``` bicep
        param openAIInstances = [
            eastUs
            eastus2
            canadaEast  
        ]
        ```

2. Login to the Azure CLI:  `az login`
3. Run the deployment command

    ``` PowerShell
    .\deploy.ps1 -appName "<less than 6 characters>" -location "<azure region>" -docIntelligenceInstanceCount "<number needed>"
    ```

These scripts will create all of the Azure resources and RBAC role assignments needed for the demonstration.

### Running a demonstration

To exercise the code and run the demo, follow these steps:


1. Upload sample file to the storage account's `documents` container. To help with this, you can try the supplied PowerShell script [`BulkUploadAndDuplicate.ps1`](Scripts/BulkUploadAndDuplicate.ps1). This script will take a directory of local files and upload them to the storage container. Then, based on your settings, duplicate them to help you easily create a large library of files to process

    ```Powershell
    .\BulkUploadAndDuplicate.ps1 -path "<path to dir with sample file>" -storageAccountName "<storage account name>" -containerName "incoming" -counterStart 0 -duplicateCount 10
    ```

    The sample script above would would upload all of the files found in the `-path` directory, then create copies of them prefixed with 000000 through 000010. You can of course upload the files any way you see fit.

2. In the Azure portal, navigate to the resource group that was created and locate the function with the `Queueing` in the name. Then select the Functions list and select the function method `DocumentQueueing`. In the "Code + Test" link, select Test/Run and hit "Run" (no query parameters are needed). This will kick off the queueing process for all of the files in the `documents` storage container. The output will be the number of files that were queued.

3. Once messages start getting queued, the `DocumentIntelligence` function will start picking up the messages and begin processing. You should see the number of messages in the `docqueue` queue go down as they are successfully processed. You will also see new files getting created in the `processresults` container.

4. Simultaneously, as the `DocumentIntelligence` function completes it's processing and queues messages in the `docqueue` queue, the `AiSearchIndexing` function will start picking up messages in the `toindexqueue` and sent the extracted text in the `processresults` container to Azure OpenAI for embedding calculation and then Azure AI Search for indexing. Also the `Mover` function will begin picking up those messages and moving the processed files from the `processed` container into the `completed` container.

5. You can review the execution and timings of the end to end process



