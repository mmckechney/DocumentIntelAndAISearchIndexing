using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Indexes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AzureUtilities.Models
{
    public class CustomFieldIndexModel
    {
      [SimpleField(IsKey = true, IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string Id { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false, SearchAnalyzerName =  "StandardLucene")]
      public IList<double> Embedding { get; set; } // Assuming it's a collection of strings  

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false, SearchAnalyzerName = "StandardLucene")]
      public string Text { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string Description { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string AdditionalMetadata { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public string ExternalSourceName { get; set; }

      [SimpleField(IsFilterable = true, IsSortable = false, IsFacetable = false)]
      public bool IsReference { get; set; }

      [SearchableField(IsFilterable = true, IsSortable = false, IsFacetable = false, SearchAnalyzerName = "StandardLucene")]
      public IList<string> CustomField { get; set; } 
   }
}

