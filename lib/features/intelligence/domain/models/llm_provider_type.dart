/// Identifies a concrete LLM backend that can be swapped behind the
/// [LlmProvider] abstraction.
///
/// The Intelligence Layer never imports HTTP code directly; it talks to
/// [LlmProvider] and lets the provider factory map this enum to an adapter.
enum LlmProviderType { mock, local, openai, gemini, ollama }
