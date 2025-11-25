# Plan for Migrating from Semantic Kernel to Microsoft Agent Framework

## Analysis Summary

After analyzing the solution, I've identified that the project uses **Semantic Kernel for prompt-based AI operations** rather than Semantic Kernel Agents. The project:

- Uses `Microsoft.SemanticKernel` (v1.48.0) for chat completion and prompt templates
- Uses `Microsoft.SemanticKernel.Connectors.AzureOpenAI` for Azure OpenAI integration
- Uses `Microsoft.SemanticKernel.Connectors.AzureAISearch` for AI Search integration
- Uses `Microsoft.SemanticKernel.PromptTemplates.Handlebars` for Handlebars templates
- Does **NOT** use Semantic Kernel Agents (no `Microsoft.SemanticKernel.Agents.*` packages)

**Key Finding**: This solution uses Semantic Kernel's **Kernel and function invocation** for prompt engineering, not the Agents API. The Microsoft Agent Framework is specifically designed for agent-based AI interactions, not for direct kernel-based prompt invocation.

## Recommended Approach

Since this solution uses Semantic Kernel for **prompt-based completions** and **text embedding**, the appropriate modernization path is:

### Option 1: Migrate to Microsoft.Extensions.AI (Recommended)

Migrate to `Microsoft.Extensions.AI` abstractions which provide:
- `IChatClient` for chat completions (replaces Kernel-based chat)
- `IEmbeddingGenerator` for embeddings (replaces ITextEmbeddingGenerationService)
- Unified abstractions across AI providers
- Better performance and simpler APIs

### Option 2: Keep Semantic Kernel

Continue using Semantic Kernel v1.x which is still actively maintained and supported for prompt-based scenarios.

## Execution Plan (Option 1 - Microsoft.Extensions.AI)

### Phase 1: Package Updates

**Project: AzureUtilities/UtilityLibrary.csproj**

1. Remove Semantic Kernel packages:
   - `Microsoft.SemanticKernel` (v1.48.0)
   - `Microsoft.SemanticKernel.Abstractions` (v1.48.0)
   - `Microsoft.SemanticKernel.Connectors.AzureOpenAI` (v1.48.0)
   - `Microsoft.SemanticKernel.Connectors.AzureAISearch` (v1.48.0-preview)
   - `Microsoft.SemanticKernel.Plugins.Memory` (v1.48.0-alpha)
   - `Microsoft.SemanticKernel.PromptTemplates.Handlebars` (v1.48.0)
   - `Microsoft.SemanticKernel.Yaml` (v1.48.0)

2. Add Microsoft.Extensions.AI packages:
   - `Microsoft.Extensions.AI` (latest stable)
   - `Microsoft.Extensions.AI.OpenAI` (latest stable)
   - `Azure.AI.OpenAI` (keep existing for Azure OpenAI support)

### Phase 2: Code Modernization

**File: AzureUtilities/SkHelper.cs**

1. Replace `Kernel` with `IChatClient`
2. Replace `ITextEmbeddingGenerationService` with `IEmbeddingGenerator<string, Embedding<float>>`
3. Update prompt invocation from kernel-based to direct chat client calls
4. Migrate YAML prompt loading to direct prompt strings or maintain custom YAML loading
5. Update method signatures to use new AI abstractions

**File: AiSearchIndexingFunction/AiSearchIndexing.cs**

1. Update import statement from `Microsoft.SemanticKernel.Text` to appropriate text chunking library
2. Keep functionality as-is (only uses TextChunker utility)

**File: DocumentQuestionsFunction/AskQuestions.cs**

1. Update to use modernized SkHelper methods
2. Remove Semantic Kernel pragma warnings

### Phase 3: Testing & Validation

1. Build all projects to ensure no compilation errors
2. Verify functionality:
   - Question answering via `AskQuestion` method
   - Custom field extraction via `ExtractCustomFields` 
   - Embedding generation via `GetEmbeddingAsync`
   - Streaming question answering via `AskQuestionStreaming`
3. Search for any remaining Semantic Kernel references
4. Test Azure Functions end-to-end

## Important Notes

- **Agent Framework Not Applicable**: The Agent Framework is designed for agent-based scenarios (chat agents with tools, threads, multi-turn conversations). This solution uses prompt-based completion which is better suited for `Microsoft.Extensions.AI.IChatClient`.

- **Handlebars Prompts**: The migration will require handling YAML/Handlebars prompts differently, as `Microsoft.Extensions.AI` doesn't have built-in YAML prompt template support. Options include:
  - Convert YAML prompts to inline C# strings
  - Load YAML prompts and format them manually before sending to `IChatClient`
  - Create custom prompt template helper

- **Text Chunking**: `Microsoft.SemanticKernel.Text.TextChunker` may need replacement with a custom or third-party text splitting library.

- **Breaking Changes**: This is a significant refactoring that changes core AI integration patterns.

## Validation Checklist

- [x] All Semantic Kernel packages removed
- [x] Microsoft.Extensions.AI packages added and working
- [x] SkHelper class successfully migrated
- [x] All dependent functions compile without errors
- [x] AskQuestion functionality preserved (code review)
- [x] AskQuestionStreaming functionality preserved (code review)
- [x] ExtractCustomField functionality preserved (code review)
- [x] GetEmbeddingAsync functionality preserved (code review)
- [x] No Semantic Kernel references remain in code
- [ ] All Azure Functions tested end-to-end (requires runtime testing)
- [ ] Performance is acceptable or improved (requires runtime testing)

---

## ✅ Migration Status: COMPLETED

The migration has been successfully completed! All code changes are done and the solution builds without errors.

**See the detailed report:** `.github/upgrades/SemanticKernelToMicrosoftExtensionsAI_Report.md`

**Next steps for validation:**
1. Deploy to a test Azure environment
2. Run end-to-end integration tests
3. Validate all Azure Functions with real workloads
4. Monitor performance metrics
