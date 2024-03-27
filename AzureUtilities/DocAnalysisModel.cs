using Azure.AI.DocumentIntelligence;

namespace AzureUtilities
{
   public class DocAnalysisModel
   {
      public int Index { get; set; }
      public DocumentIntelligenceClient DocumentIntelligenceClient { get; set; }
      //  public DocumentAnalysisClient DocumentAnalysisClient { get; set; }
      public string Endpoint { get; set; } = string.Empty;
      private string _key = string.Empty;
      public string Key
      {
         get => _key; set
         {
            if (value.Length >= 9)
            {
               _key = value.Substring(0, 4) + new string('*', value.Length - 8) + value.Substring(value.Length - 4);
            }
            else
            {
               throw new ArgumentException("The Key value is too short!");
            }
         }
      }
   }
}
