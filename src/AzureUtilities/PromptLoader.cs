using System.Reflection;
using System.Text.RegularExpressions;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace HighVolumeProcessing.UtilityLibrary;

/// <summary>
/// Represents a prompt template loaded from YAML
/// </summary>
public class PromptTemplate
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Template { get; set; } = string.Empty;
    public string TemplateFormat { get; set; } = "handlebars";
    public List<InputVariable> InputVariables { get; set; } = new();
    public Dictionary<string, ExecutionSetting> ExecutionSettings { get; set; } = new();
}

public class InputVariable
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsRequired { get; set; }
}

public class ExecutionSetting
{
    public string? ModelId { get; set; }
    public int MaxTokens { get; set; } = 3500;
    public double Temperature { get; set; } = 0.9;
}

/// <summary>
/// Helper class for loading and processing YAML prompt templates
/// </summary>
public static class PromptLoader
{
    private static readonly IDeserializer _deserializer = new DeserializerBuilder()
        .WithNamingConvention(UnderscoredNamingConvention.Instance)
        .Build();

    /// <summary>
    /// Loads all YAML prompt templates from embedded resources
    /// </summary>
    public static Dictionary<string, PromptTemplate> LoadEmbeddedPrompts()
    {
        var prompts = new Dictionary<string, PromptTemplate>();
        var assembly = Assembly.GetExecutingAssembly();
        var resources = assembly.GetManifestResourceNames()
            .Where(r => r.EndsWith(".yaml", StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var resourceName in resources)
        {
            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream == null) continue;

            using var reader = new StreamReader(stream);
            var content = reader.ReadToEnd();
            
            try
            {
                var template = _deserializer.Deserialize<PromptTemplate>(content);
                if (template != null)
                {
                    // Extract the prompt name from resource name
                    var tmp = resourceName.Substring(0, resourceName.LastIndexOf('.'));
                    var key = tmp.Substring(tmp.LastIndexOf('.') + 1);
                    prompts[key] = template;
                }
            }
            catch (Exception ex)
            {
                // Log error but continue loading other prompts
                Console.WriteLine($"Error loading prompt from {resourceName}: {ex.Message}");
            }
        }

        return prompts;
    }

    /// <summary>
    /// Renders a Handlebars-style template with the provided variables
    /// </summary>
    public static string RenderTemplate(string template, Dictionary<string, string> variables)
    {
        var rendered = template;
        
        // Replace {{variable}} with actual values
        foreach (var kvp in variables)
        {
            var pattern = $@"{{\{{{{\s*{Regex.Escape(kvp.Key)}\s*}}}}}}";
            rendered = Regex.Replace(rendered, pattern, kvp.Value);
        }

        return rendered;
    }

    /// <summary>
    /// Parses the template into system and user messages
    /// </summary>
    public static List<(string Role, string Content)> ParseMessages(string template)
    {
        var messages = new List<(string Role, string Content)>();
        
        // Match <message role="...">content</message>
        var messagePattern = @"<message\s+role=""([^""]+)"">\s*(.*?)\s*</message>";
        var matches = Regex.Matches(template, messagePattern, RegexOptions.Singleline);

        foreach (Match match in matches)
        {
            var role = match.Groups[1].Value.ToLower();
            var content = match.Groups[2].Value.Trim();
            messages.Add((role, content));
        }

        return messages;
    }
}
