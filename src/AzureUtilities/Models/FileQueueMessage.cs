using Microsoft.Extensions.Logging;

namespace HighVolumeProcessing.UtilityLibrary.Models
{
   public class FileQueueMessage
   {
      public string id { get; set; } = string.Empty;
      public string SourceFileName { get; set; } = string.Empty;
      public string ProcessedFileName { get; set; } = string.Empty;
      public string ContainerName { get; set; } = string.Empty;
      public int RecognizerIndex { get; set; } = 0;
      public List<string> CustomIndexFieldValues { get; set; } = new();
      public List<TrackingItem> Tracking = new();

      public FileQueueMessage CloneWithOverrides(string? containerName = null, string? processedFileName = null, List<string>? customIndexFieldValues = null)
      {
         return new FileQueueMessage()
         {
            id = this.id,
            SourceFileName = this.SourceFileName,
            ProcessedFileName = processedFileName ?? this.ProcessedFileName,
            ContainerName = containerName ?? this.ContainerName,
            RecognizerIndex = this.RecognizerIndex,
            CustomIndexFieldValues = customIndexFieldValues ?? new List<string>(this.CustomIndexFieldValues)
         };
      }

      public FileQueueMessage UpdateFromMessage(FileQueueMessage item)
      {

         this.ProcessedFileName = item.ProcessedFileName ?? this.ProcessedFileName;
         this.ContainerName = item.ContainerName ?? this.ContainerName;
         this. CustomIndexFieldValues = item.CustomIndexFieldValues ?? new List<string>(this.CustomIndexFieldValues);
         if (item.Tracking.Count > 0)
         {
            this.Tracking.Add(item.Tracking.Last());
         }
         return this;
      }

      public override string ToString()
      {
         return $"SourceFileName: {SourceFileName}, ProcessedFileName: {ProcessedFileName}, ContainerName: {ContainerName}, Id: {id}, RecognizerIndex: {RecognizerIndex}, CustomIndexFieldValues: {string.Join(", ", CustomIndexFieldValues)}";

      }
   }
}
