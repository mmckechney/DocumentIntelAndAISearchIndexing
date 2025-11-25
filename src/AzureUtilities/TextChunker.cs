using System.Text;

namespace HighVolumeProcessing.UtilityLibrary;

/// <summary>
/// Utility class for splitting text into smaller chunks based on token limits.
/// </summary>
public static class TextChunker
{
    private const int DefaultMaxTokens = 8000;
    private const int CharsPerToken = 4; // Approximate characters per token for estimation

    /// <summary>
    /// Splits plain text paragraphs into chunks that fit within token limits.
    /// </summary>
    /// <param name="lines">Collection of text lines to chunk</param>
    /// <param name="maxTokensPerChunk">Maximum tokens allowed per chunk</param>
    /// <returns>List of text chunks</returns>
    public static List<string> SplitPlainTextParagraphs(IEnumerable<string> lines, int maxTokensPerChunk = DefaultMaxTokens)
    {
        var chunks = new List<string>();
        var currentChunk = new StringBuilder();
        var currentTokenCount = 0;
        var maxCharsPerChunk = maxTokensPerChunk * CharsPerToken;

        foreach (var line in lines)
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            var lineTokenCount = EstimateTokenCount(line);

            // If adding this line would exceed the limit, save current chunk and start new one
            if (currentTokenCount + lineTokenCount > maxTokensPerChunk && currentChunk.Length > 0)
            {
                chunks.Add(currentChunk.ToString().Trim());
                currentChunk.Clear();
                currentTokenCount = 0;
            }

            // If a single line exceeds the limit, split it further
            if (lineTokenCount > maxTokensPerChunk)
            {
                var subChunks = SplitLongLine(line, maxCharsPerChunk);
                foreach (var subChunk in subChunks)
                {
                    if (currentChunk.Length > 0)
                    {
                        chunks.Add(currentChunk.ToString().Trim());
                        currentChunk.Clear();
                        currentTokenCount = 0;
                    }
                    chunks.Add(subChunk.Trim());
                }
            }
            else
            {
                currentChunk.AppendLine(line);
                currentTokenCount += lineTokenCount;
            }
        }

        // Add any remaining content
        if (currentChunk.Length > 0)
        {
            chunks.Add(currentChunk.ToString().Trim());
        }

        return chunks;
    }

    private static int EstimateTokenCount(string text)
    {
        // Simple estimation: approximately 4 characters per token
        return (text.Length + CharsPerToken - 1) / CharsPerToken;
    }

    private static List<string> SplitLongLine(string line, int maxChars)
    {
        var chunks = new List<string>();
        var words = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var currentChunk = new StringBuilder();

        foreach (var word in words)
        {
            if (currentChunk.Length + word.Length + 1 > maxChars)
            {
                if (currentChunk.Length > 0)
                {
                    chunks.Add(currentChunk.ToString().Trim());
                    currentChunk.Clear();
                }

                // If single word is too long, split it by character
                if (word.Length > maxChars)
                {
                    for (int i = 0; i < word.Length; i += maxChars)
                    {
                        chunks.Add(word.Substring(i, Math.Min(maxChars, word.Length - i)));
                    }
                }
                else
                {
                    currentChunk.Append(word).Append(' ');
                }
            }
            else
            {
                currentChunk.Append(word).Append(' ');
            }
        }

        if (currentChunk.Length > 0)
        {
            chunks.Add(currentChunk.ToString().Trim());
        }

        return chunks;
    }
}
