namespace HighVolumeProcessing.UtilityLibrary.Models
{
   public class FileQueueMessage
   {
      public string Id { get; set; } = string.Empty;
      public string SourceFileName { get; set; } = string.Empty;
      public string ProcessedFileName { get; set; } = string.Empty;
      public string ContainerName { get; set; } = string.Empty;
      public int RecognizerIndex { get; set; } = 0;
      public List<string> CustomIndexFieldValues { get; set; } = new List<string>();

      public FileQueueMessage CloneWithOverrides(string? containerName = null, string? processedFileName = null, List<string>? customIndexFieldValues = null)
      {
         return new FileQueueMessage()
         {
            Id = this.Id,
            SourceFileName = this.SourceFileName,
            ProcessedFileName = processedFileName ?? this.ProcessedFileName,
            ContainerName = containerName ?? this.ContainerName,
            RecognizerIndex = this.RecognizerIndex,
            CustomIndexFieldValues = customIndexFieldValues ?? new List<string>(this.CustomIndexFieldValues)
         };
      }

      public override string ToString()
      {
         return $"SourceFileName: {SourceFileName}, ProcessedFileName: {ProcessedFileName}, ContainerName: {ContainerName}, Id: {Id}, RecognizerIndex: {RecognizerIndex}, CustomIndexFieldValues: {string.Join(", ", CustomIndexFieldValues)}";

      }
   }
}
