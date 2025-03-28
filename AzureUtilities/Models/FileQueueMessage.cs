namespace HighVolumeProcessing.UtilityLibrary
{
   public class FileQueueMessage
   {
      public string SourceFileName { get; set; } = string.Empty;
      public string ProcessedFileName { get; set; } = string.Empty;
      public string ContainerName { get; set; } = string.Empty;
      public int RecognizerIndex { get; set; } = 0;
      public List<string> CustomIndexFieldValues { get; set; } = new List<string>();

      public FileQueueMessage CloneWithOverrides(string? containerName = null, string? processedFileName = null, List<string>? customIndexFieldValues = null)
      {
         return new FileQueueMessage()
         {
            SourceFileName = this.SourceFileName,
            ProcessedFileName = processedFileName ?? this.ProcessedFileName,
            ContainerName = containerName ?? this.ContainerName,
            RecognizerIndex = this.RecognizerIndex,
            CustomIndexFieldValues = customIndexFieldValues ?? new List<string>(this.CustomIndexFieldValues)
         };
      }

      public override string ToString()
      {
         return $"SourceFileName: {SourceFileName}, ProcessedFileName: {ProcessedFileName}, ContainerName: {ContainerName}, RecognizerIndex: {RecognizerIndex}, CustomIndexFieldValues: {string.Join(", ", CustomIndexFieldValues)}";

      }
   }
}
