using Azure;
using Azure.Security.KeyVault.Secrets;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Logging;
using System.Text;
namespace AzureUtilities
{
   public class StorageHelper
   {
      private readonly ILogger<StorageHelper> logger;
      private Dictionary<string, BlobContainerClient> blobClients = new();
      private BlobServiceClient serviceClient = null;
      public StorageHelper(ILogger<StorageHelper> logger)
      {
         this.logger = logger;

      }

      public BlobClient GetBlobClient(string containerName, string blobname)
      {
         var containerClient = GetContainerClient(containerName);
         return containerClient.GetBlobClient(blobname);
      }

      public async Task<Response<BlobContentInfo>> UploadBlobAsync(string containerName, string fileName, string content)
      {
         Response<BlobContentInfo> resp;
         using (MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(content)))
         {
            var containerClient = GetContainerClient(containerName);
            resp = await containerClient.UploadBlobAsync(fileName, ms);
         }
         return resp;
      }

      public async Task<string> GetFileContents(string containerName, string fileName)
      {

         var blobClient = GetBlobClient(containerName, fileName);
         using (var stream = await blobClient.OpenReadAsync())
         using (var reader = new StreamReader(stream))
         {
            string contents = await reader.ReadToEndAsync();
            return contents;
         }
      }
      public BlobContainerClient GetContainerClient(string containerName)
      {
         var key = $"{containerName}-{Settings.StorageAccountName}";
         if (blobClients.ContainsKey(key))
         {
            return blobClients[key];
         }
         else
         {
            if(serviceClient == null)
            {
               serviceClient = CreateStorageClient(Settings.StorageAccountName);
            }

            var client = CreateBlobContainerClient(containerName, serviceClient);
            blobClients.Add(key, client);
            return client;
         }
      }

      private BlobServiceClient CreateStorageClient(string storageAccountName)
      {
         var serviceClient = new BlobServiceClient(new Uri($"https://{storageAccountName}.blob.core.windows.net"), AadHelper.TokenCredential);
         return serviceClient;
      }

      private BlobContainerClient CreateBlobContainerClient(string containerName, BlobServiceClient serviceClient)
      {
         var container = serviceClient.GetBlobContainerClient(containerName);
         return container;
      }
      //private BlobContainerClient CreateBlobContainerClient(string containerName, string storageAccountName)
      //{
      //   var serviceClient = new BlobServiceClient(new Uri($"https://{storageAccountName}.blob.core.windows.net"), AadHelper.TokenCredential);
      //   return CreateBlobContainerClient(containerName, serviceClient);
      //}

      //public async Task<string> GetStorageConnectionString(string keyVaultName, string storageAcctName)
      //{
      //   CancellationTokenSource src = new CancellationTokenSource();

      //   SecretClient secretClient = new SecretClient(new Uri($"https://{keyVaultName}.vault.azure.net"), AadHelper.TokenCredential);
      //   var secret = await secretClient.GetSecretAsync("STORAGE-KEY");
      //   var key = secret.Value.Value;
      //   var connectionStr = $"DefaultEndpointsProtocol=https;AccountName={storageAcctName};AccountKey={key};EndpointSuffix=core.windows.net";
      //   return connectionStr;


      //}


   }
}
