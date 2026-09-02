import 'dart:async';
import 'ai_provider.dart';
import 'ollama_ai_provider.dart';
import 'openai_provider.dart';
import 'gemini_provider.dart';
import 'local_assistant.dart';
import 'storage_service.dart';
import 'chat_proxy.dart';
import '../core/constants/ollama_config.dart';
import '../core/constants/app_keys.dart';
enum AiProviderType { local, ollama, openai, gemini, groq, openRouter }

class AssistantService {
  AiProviderType _providerType = AiProviderType.ollama;
  AiProvider? _remoteProvider;
  String _apiKey = '';
  final _local = LocalAssistant();
  final _storage = StorageService();
  final _proxy = ChatProxy();
  String _ollamaBaseUrl = '';
  String _ollamaModel = '';
  String _geminiModel = '';
  String _groqModel = '';
  String _openRouterModel = '';

  String get ollamaServerUrl => _ollamaBaseUrl.isEmpty
      ? OllamaConfig.defaultBaseUrl
      : _ollamaBaseUrl;

  String get ollamaModel => _ollamaModel.isEmpty ? OllamaConfig.model : _ollamaModel;

  /// The active Gemini model. Guards against a model saved earlier that has
  /// since been retired by Google — those fall back to the default so the
  /// dropdown never receives a value missing from its items.
  String get geminiModel {
    final stored = _geminiModel.trim();
    if (stored.isEmpty || !kGeminiModels.contains(stored)) {
      return kDefaultGeminiModel;
    }
    return stored;
  }

  String? _lastPrompt;
  String? _lastPersona;
  String? _lastDisplayName;
  List<Map<String, String>>? _lastHistory;

  AiProviderType get providerType => _providerType;
  String get providerName => _providerType == AiProviderType.local
      ? 'Local'
      : _remoteProvider?.name ?? 'None';

  String? get lastPrompt => _lastPrompt;

  Future<void> loadConfig() async {
    final config = await _storage.loadAiConfig();
    _providerType = config['provider'] as AiProviderType? ??
        (AppKeys.hasEmbeddedGroqKey
            ? AiProviderType.groq
            : AppKeys.hasEmbeddedGeminiKey
                ? AiProviderType.gemini
                : AiProviderType.local);
    _ollamaBaseUrl = await _storage.loadOllamaUrl();
    _ollamaModel = await _storage.loadOllamaModel();
    _geminiModel = await _storage.loadGeminiModel();
    _groqModel = await _storage.loadGroqModel();
    _openRouterModel = await _storage.loadOpenRouterModel();
    final apiKey = config['apiKey'] as String?;
    _apiKey = resolveKey(_providerType, apiKey);
    if (_providerType == AiProviderType.ollama) {
      _initRemote(_providerType, '');
      _warmupOllama();
    } else if (_apiKey.isNotEmpty) {
      _initRemote(_providerType, _apiKey);
    }
  }

  /// Picks the key for a provider: whatever the user saved, falling back to
  /// the embedded build-time keys so the app works out of the box.
  /// A stored Gemini key only overrides the embedded one when it looks
  /// structurally valid (AIza... legacy or AQ. current format).
  String resolveKey(AiProviderType type, String? stored) {
    final trimmed = stored?.trim() ?? '';
    switch (type) {
      case AiProviderType.gemini:
        final looksValid =
            trimmed.startsWith('AIza') || trimmed.startsWith('AQ.');
        if (looksValid) return trimmed;
        if (AppKeys.hasEmbeddedGeminiKey) return AppKeys.geminiApiKey.trim();
        return '';
      case AiProviderType.groq:
        if (trimmed.startsWith('gsk_')) return trimmed;
        if (AppKeys.hasEmbeddedGroqKey) return AppKeys.groqApiKey.trim();
        return '';
      case AiProviderType.openRouter:
        if (trimmed.startsWith('sk-or-')) return trimmed;
        if (AppKeys.hasEmbeddedOpenRouterKey) {
          return AppKeys.openRouterApiKey.trim();
        }
        return '';
      case AiProviderType.openai:
        if (trimmed.startsWith('sk-')) return trimmed;
        if (AppKeys.hasEmbeddedOpenaiKey) return AppKeys.openaiApiKey.trim();
        return '';
      default:
        return trimmed;
    }
  }

  /// True when no personal key is saved and the baked-in key is being used.
  bool get usingEmbeddedGeminiKey =>
      _providerType == AiProviderType.gemini &&
      AppKeys.hasEmbeddedGeminiKey &&
      _apiKey == AppKeys.geminiApiKey.trim();

  void _warmupOllama() {
    if (_remoteProvider is OllamaAiProvider) {
      unawaited((_remoteProvider as OllamaAiProvider).warmup());
    }
  }

  void _initRemote(AiProviderType type, String apiKey) {
    switch (type) {
      case AiProviderType.ollama:
        _remoteProvider = OllamaAiProvider(
            baseUrl: _ollamaBaseUrl.isEmpty ? null : _ollamaBaseUrl,
            model: _ollamaModel.isEmpty ? null : _ollamaModel);
        break;
      case AiProviderType.openai:
        _remoteProvider = OpenAIProvider(apiKey);
        break;
      case AiProviderType.gemini:
        _remoteProvider = GeminiProvider(apiKey, model: geminiModel);
        break;
      case AiProviderType.groq:
        _remoteProvider = OpenAIProvider(
          apiKey,
          model: groqModel,
          baseUrl: 'https://api.groq.com/openai/v1',
          name: 'Groq',
        );
        break;
      case AiProviderType.openRouter:
        _remoteProvider = OpenAIProvider(
          apiKey,
          model: openRouterModel,
          baseUrl: 'https://openrouter.ai/api/v1',
          name: 'OpenRouter',
          extraHeaders: {
            'HTTP-Referer': 'https://banataq.app',
            'X-Title': 'Banataq',
          },
        );
        break;
      case AiProviderType.local:
        _remoteProvider = null;
        break;
    }
  }

  String get groqModel {
    final stored = _groqModel.trim();
    if (stored.isEmpty || !kGroqModels.contains(stored)) {
      return kDefaultGroqModel;
    }
    return stored;
  }

  String get openRouterModel {
    final stored = _openRouterModel.trim();
    if (stored.isEmpty || !kOpenRouterModels.contains(stored)) {
      return kDefaultOpenRouterModel;
    }
    return stored;
  }

  Future<void> setOllamaUrl(String url) async {
    _ollamaBaseUrl = url.trim();
    await _storage.saveOllamaUrl(_ollamaBaseUrl);
    if (_providerType == AiProviderType.ollama) {
      _initRemote(_providerType, '');
      _warmupOllama();
    }
  }

  Future<void> setOllamaModel(String model) async {
    _ollamaModel = model.trim();
    await _storage.saveOllamaModel(_ollamaModel);
    if (_providerType == AiProviderType.ollama) {
      _initRemote(_providerType, '');
      _warmupOllama();
    }
  }

  Future<void> setGeminiModel(String model) async {
    final trimmed = model.trim();
    _geminiModel = kGeminiModels.contains(trimmed) ? trimmed : kDefaultGeminiModel;
    await _storage.saveGeminiModel(_geminiModel);
    if (_providerType == AiProviderType.gemini) {
      _initRemote(_providerType, _apiKey);
    }
  }

  Future<void> setGroqModel(String model) async {
    final trimmed = model.trim();
    _groqModel = kGroqModels.contains(trimmed) ? trimmed : kDefaultGroqModel;
    await _storage.saveGroqModel(_groqModel);
    if (_providerType == AiProviderType.groq) {
      _initRemote(_providerType, _apiKey);
    }
  }

  Future<void> setOpenRouterModel(String model) async {
    final trimmed = model.trim();
    _openRouterModel =
        kOpenRouterModels.contains(trimmed) ? trimmed : kDefaultOpenRouterModel;
    await _storage.saveOpenRouterModel(_openRouterModel);
    if (_providerType == AiProviderType.openRouter) {
      _initRemote(_providerType, _apiKey);
    }
  }

  Future<void> setProvider(AiProviderType type, String apiKey) async {
    _providerType = type;
    final trimmed = apiKey.trim();
    _apiKey = trimmed.isNotEmpty ? trimmed : resolveKey(type, null);
    if (type != AiProviderType.local) {
      _initRemote(type, type == AiProviderType.ollama ? '' : _apiKey);
      if (type == AiProviderType.ollama) _warmupOllama();
    } else {
      _remoteProvider = null;
    }
    // Don't persist embedded keys themselves, so rotating them in a future
    // build takes effect for existing installs too.
    final usesEmbedded = (AppKeys.hasEmbeddedGeminiKey &&
            type == AiProviderType.gemini &&
            _apiKey == AppKeys.geminiApiKey.trim()) ||
        (AppKeys.hasEmbeddedGroqKey &&
            type == AiProviderType.groq &&
            _apiKey == AppKeys.groqApiKey.trim()) ||
        (AppKeys.hasEmbeddedOpenRouterKey &&
            type == AiProviderType.openRouter &&
            _apiKey == AppKeys.openRouterApiKey.trim());
    final keyToPersist = usesEmbedded ? '' : _apiKey;
    await _storage.saveAiConfig(type, type == AiProviderType.ollama ? '' : keyToPersist);
  }

  /// Returns a user-facing status string after probing the Ollama server.
  /// Used by the in-app connection tester so the user can see whether the
  /// phone can actually reach the machine running Ollama.
  Future<String> testOllamaConnection() async {
    final provider = _remoteProvider;
    if (provider is! OllamaAiProvider) {
      return 'Ollama is not the active provider.';
    }
    try {
      final reachable = await provider.testConnection();
      return reachable
          ? 'Connected to Ollama at ${provider.baseUrl}'
          : 'Ollama server not reachable at ${provider.baseUrl}';
    } catch (e) {
      return 'Connection failed: ${e.toString()}';
    }
  }

  /// Returns a user-facing status string after probing the Gemini API with
  /// the saved key (using the active Gemini model).
  Future<String> testGeminiConnection() async {
    final provider = _remoteProvider;
    if (provider is! GeminiProvider) {
      return 'Gemini is not the active provider. Add your key first.';
    }
    try {
      final result = await provider.testConnection();
      return '$result (${usingEmbeddedGeminiKey ? 'built-in key' : 'personal key'})';
    } catch (e) {
      return 'Connection failed: ${e.toString()}';
    }
  }

  String _unreachableAiMessage(Object e) =>
      "I couldn't reach the local AI model. Make sure your phone is on the same network as your computer and Ollama is running, then try again. (${e.toString()})";

  Future<String> _enrichedPersona(String? persona) async {
    final prefs = await _storage.loadOnboardingPreferences();
    final line = prefs?.assistantContextLine();
    if (line == null || line.isEmpty) return persona ?? '';
    final base = persona?.trim() ?? '';
    return base.isEmpty ? 'User preferences: $line.' : '$base\nUser preferences: $line.';
  }

  Future<String> reply(
    String input, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async {
    _lastPrompt = input;
    _lastPersona = persona;
    _lastDisplayName = displayName;
    _lastHistory = history;
    final enriched = await _enrichedPersona(persona);
    final activeModel = _providerType == AiProviderType.gemini ? geminiModel : _providerType == AiProviderType.groq ? groqModel : _providerType == AiProviderType.openRouter ? openRouterModel : ollamaModel;

    if (_proxy.enabled) {
      try {
        return await _proxy.proxyGenerate(prompt: input, model: activeModel, history: history);
      } catch (e) {
        // fall through to direct if proxy fails
      }
    }

    if (_providerType != AiProviderType.local && _remoteProvider != null) {
      try {
        return await _remoteProvider!.generateResponse(
          input,
          persona: enriched.isEmpty ? null : enriched,
          displayName: displayName,
          history: history,
        );
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isOpenRouterFallback = _providerType == AiProviderType.openRouter && (msg.contains('free limit') || msg.contains('unavailable') || msg.contains('model not') || msg.contains('429') || msg.contains('rate limit'));
        if (isOpenRouterFallback && AppKeys.hasEmbeddedGroqKey) {
          try {
            final fallback = OpenAIProvider(AppKeys.groqApiKey.trim(), model: kDefaultGroqModel, baseUrl: 'https://api.groq.com/openai/v1', name: 'Groq');
            return await fallback.generateResponse(input, persona: enriched.isEmpty ? null : enriched, displayName: displayName, history: history);
          } catch (_) {}
        }
        if (_providerType == AiProviderType.ollama) {
          return _unreachableAiMessage(e);
        }
        return 'AI request failed: ${e.toString()}\n\nFalling back to local mode.';
      }
    }
    return _local.reply(input);
  }

  Stream<String> replyStream(
    String input, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async* {
    _lastPrompt = input;
    _lastPersona = persona;
    _lastDisplayName = displayName;
    _lastHistory = history;
    final enriched = await _enrichedPersona(persona);
    final activeModel = _providerType == AiProviderType.gemini ? geminiModel : _providerType == AiProviderType.groq ? groqModel : _providerType == AiProviderType.openRouter ? openRouterModel : ollamaModel;

    if (_proxy.enabled) {
      try {
        yield* _proxy.proxyStream(prompt: input, model: activeModel, history: history);
        return;
      } catch (e) {
        // fall through
      }
    }

    if (_providerType != AiProviderType.local && _remoteProvider != null) {
      try {
        yield* _remoteProvider!.generateResponseStream(
          input,
          persona: enriched.isEmpty ? null : enriched,
          displayName: displayName,
          history: history,
        );
        return;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isOpenRouterFallback = _providerType == AiProviderType.openRouter && (msg.contains('free limit') || msg.contains('unavailable') || msg.contains('model not') || msg.contains('429') || msg.contains('rate limit'));
        if (isOpenRouterFallback && AppKeys.hasEmbeddedGroqKey) {
          try {
            final fallback = OpenAIProvider(AppKeys.groqApiKey.trim(), model: kDefaultGroqModel, baseUrl: 'https://api.groq.com/openai/v1', name: 'Groq');
            yield* fallback.generateResponseStream(input, persona: enriched.isEmpty ? null : enriched, displayName: displayName, history: history);
            return;
          } catch (_) {}
        }
        if (_providerType == AiProviderType.ollama) {
          yield _unreachableAiMessage(e);
          return;
        }
        rethrow;
      }
    }
    final result = await _local.reply(input);
    yield result;
  }

  bool get canRegenerate => _lastPrompt != null && _remoteProvider != null;

  Future<String> regenerate({
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async {
    if (_lastPrompt == null) throw Exception('No previous prompt');
    return reply(
      _lastPrompt!,
      persona: persona ?? _lastPersona,
      displayName: displayName ?? _lastDisplayName,
      history: history ?? _lastHistory,
    );
  }

  Stream<String> regenerateStream({
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) {
    if (_lastPrompt == null) throw Exception('No previous prompt');
    return replyStream(
      _lastPrompt!,
      persona: persona ?? _lastPersona,
      displayName: displayName ?? _lastDisplayName,
      history: history ?? _lastHistory,
    );
  }
}
