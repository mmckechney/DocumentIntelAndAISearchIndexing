using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;

namespace HighVolumeProcessing.UtilityLibrary.Models
{
   public class CustomFieldIndexModel
   {
      [SimpleField(IsKey = true, IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string Id { get; set; }

      [VectorSearchField(VectorSearchDimensions = 1536, VectorSearchProfileName = Settings.VectorSearchProfileName)]
      public IList<Single> Embedding { get; set; } // Assuming it's a collection of strings  

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false, SearchAnalyzerName = "standard.lucene", IndexAnalyzerName = "standard.lucene")]
      public string Text { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string FileName { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string Description { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string AdditionalMetadata { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string ExternalSourceName { get; set; }

      [SimpleField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public bool IsReference { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false, SearchAnalyzerName = "standard.lucene", IndexAnalyzerName = "standard.lucene")]
      public IList<string> CustomField { get; set; }
   }
}

