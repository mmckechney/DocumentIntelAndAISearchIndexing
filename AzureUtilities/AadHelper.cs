using Azure.Core;
using Azure.Identity;

namespace AzureUtilities
{
   public class AadHelper
   {
      private static TokenCredential? _tokenCred = null;
      public static TokenCredential TokenCredential
      {
         get
         {
            if (_tokenCred == null)

            {
               _tokenCred = new ChainedTokenCredential(
                    new AzureCliCredential(),
                    new ManagedIdentityCredential()
                  );
            }
            return _tokenCred;
         }
      }
   }
}
