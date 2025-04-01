using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HighVolumeProcessing.UtilityLibrary.Models
{
   public class TrackingItem
   {
      public TrackingItem(string source, string status, DateTime eventTime)
      {
         this.Source = source;
         this.Status = status;
         this.EventTime = eventTime;
      }
      public readonly string Source;
      public readonly string Status;
      public readonly DateTime EventTime;
   }
}
