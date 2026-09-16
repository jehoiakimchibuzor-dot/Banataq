/// No keys are baked into the binary. App calls Functions proxy /api/chat
/// which holds keys in Secret Manager. For local dev, pass via --dart-define.
/// Stored user BYOK (if any) lives in flutter_secure_storage, not SharedPreferences.
class AppKeys {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_KEY',
    defaultValue: '',
  );
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_KEY',
    defaultValue: '',
  );
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_KEY',
    defaultValue: '',
  );
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_KEY',
    defaultValue: '',
  );

  static bool get hasEmbeddedGeminiKey => geminiApiKey.trim().isNotEmpty;
  static bool get hasEmbeddedGroqKey => groqApiKey.trim().isNotEmpty;
  static bool get hasEmbeddedOpenRouterKey =>
      openRouterApiKey.trim().isNotEmpty;
  static bool get hasEmbeddedOpenaiKey => openaiApiKey.trim().isNotEmpty;

  /// Proxy base — set via --dart-define=`PROXY_URL`=https://`<region>`-banataq-80a9b.cloudfunctions.net
  static const String proxyUrl = String.fromEnvironment(
    'PROXY_URL',
    defaultValue: '',
  );
  static bool get useProxy => proxyUrl.trim().isNotEmpty;
}

/// Gemini free-tier models — via proxy. Verify at https://aistudio.google.com
const List<String> kGeminiModels = [
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-flash-lite-latest',
  'gemini-2.5-flash-lite',
  'gemini-3.1-flash-lite',
  'gemini-3.1-pro-preview',
];

const String kDefaultGeminiModel = 'gemini-3.7-flash';

/// Groq free-tier — all via Groq free quota
const List<String> kGroqModels = [
  'qwen/qwen3.6-27b',
  'openai/gpt-oss-120b',
  'llama-3.3-70b-versatile',
  'llama-3.1-8b-instant',
  'deepseek-r1-distill-llama-70b',
  'allam-2-7b',
];

const String kDefaultGroqModel = 'qwen/qwen3.6-27b';

/// OpenRouter free — :free suffix = no cost
const List<String> kOpenRouterModels = [
  'nvidia/nemotron-3-nano-30b-a3b:free',
  'google/gemma-4-31b-it:free',
  'z-ai/glm-5.2:free',
  'nvidia/nemotron-3-super-120b-a12b:free',
  'deepseek/deepseek-r1:free',
  'deepseek/deepseek-chat:free',
  'meta-llama/llama-3.2-3b-instruct:free',
  'meta-llama/llama-3.2-90b-vision-instruct:free',
  'qwen/qwen-2.5-7b-instruct:free',
  'qwen/qwen-2.5-72b-instruct:free',
  'mistralai/mistral-7b-instruct:free',
  'mistralai/mistral-nemo:free',
  'google/gemma-2-9b-it:free',
];

const String kDefaultOpenRouterModel = 'google/gemma-2-9b-it:free';

/// HuggingFace Inference free — proxied as OpenAI-compatible
const List<String> kHfModels = [
  'HuggingFaceH4/zephyr-7b-beta',
  'mistralai/Mistral-7B-Instruct-v0.3',
];

/// Unified free catalog for UI (proxy picks cheapest)
const List<String> kAllFreeModels = [
  ...kGeminiModels,
  ...kGroqModels,
  ...kOpenRouterModels,
];
