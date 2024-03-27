namespace AzureUtilities
{
   public class FileQueueMessage
   {
      public string FileName { get; set; } = string.Empty;
      public string ContainerName { get; set; } = string.Empty;
      public int RecognizerIndex { get; set; } = 0;
   }
}
