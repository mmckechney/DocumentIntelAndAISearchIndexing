using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Logging;
using System.Text;
namespace HighVolumeProcessing.UtilityLibrary
{
   public class StorageHelper
   {
      private readonly ILogger<StorageHelper> logger;
      private Dictionary<string, BlobContainerClient> blobClients = new();
      private BlobServiceClient serviceClient = null;
      Settings settings;
      public StorageHelper(ILogger<StorageHelper> logger,Settings settings)
      {
         this.logger = logger;
         this.settings = settings;

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

      private object lockObject = new object();
      public BlobContainerClient GetContainerClient(string containerName)
      {
         lock (lockObject)
         {
            var key = $"{containerName}-{settings.StorageAccountName}";
            if (blobClients.ContainsKey(key))
            {
               return blobClients[key];
            }
            else
            {


               if (serviceClient == null)
               {
                  serviceClient = CreateStorageClient(settings.StorageAccountName);
               }

               var client = CreateBlobContainerClient(containerName, serviceClient);
               try
               {

                  blobClients.Add(key, client);
               }

               catch (Exception exe)
               {
                  logger.LogError($"Error adding client '{key}' to BlobClient collection: {exe.Message}.{Environment.NewLine}{string.Join(",", blobClients?.Select(c => c.Key).ToArray())}");
               }
               return client;

            }
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

   }
}
