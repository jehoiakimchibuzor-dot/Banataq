import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../models/onboarding_preferences.dart';
import 'assistant_service.dart';

class StorageService {
  static const _profileKey = 'user_profile';
  static const _conversationsKey = 'conversations';
  static const _savedAnswersKey = 'saved_answers';
  static const _aiConfigKey = 'ai_config';
  static const _ollamaUrlKey = 'ollama_server_url';
  static const _ollamaModelKey = 'ollama_model_name';
  static const _geminiModelKey = 'gemini_model_name';
  static const _groqModelKey = 'groq_model_name';
  static const _openRouterModelKey = 'openrouter_model_name';
  static const _onboardingKey = 'onboarding_complete';
  static const _personalizationKey = 'onboarding_preferences';
  static const _personalizationDoneKey = 'personalization_complete';
  static const _firstRunCompleteKey = 'first_run_complete';

  /// True once the user has been through the first-run onboarding.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Scopes a key to a user so switching accounts never leaks data. Falls back
  /// to the unscoped key when no uid is available (e.g. guest/onboarding).
  String _scoped(String baseKey, String? userId) {
    if (userId == null || userId.isEmpty) return baseKey;
    return '${baseKey}_$userId';
  }

  Future<UserProfile?> loadProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_profileKey, userId));
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_profileKey, userId),
      jsonEncode(profile.toJson()),
    );
  }

  Future<List<Conversation>> loadConversations({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_conversationsKey, userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConversations(
    List<Conversation> conversations, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_conversationsKey, userId),
      jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<ChatMessage>> loadSavedAnswers({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_savedAnswersKey, userId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSavedAnswers(
    List<ChatMessage> answers, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoped(_savedAnswersKey, userId),
      jsonEncode(answers.map((a) => a.toJson()).toList()),
    );
  }

  Future<Map<String, dynamic>> loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_aiConfigKey);
    if (raw == null) {
      return {'provider': AiProviderType.ollama, 'apiKey': ''};
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'provider': AiProviderType.values.firstWhere(
        (e) => e.name == data['provider'],
        orElse: () => AiProviderType.ollama,
      ),
      'apiKey': data['apiKey'] as String? ?? '',
    };
  }

  Future<void> saveAiConfig(AiProviderType provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _aiConfigKey,
      jsonEncode({'provider': provider.name, 'apiKey': apiKey}),
    );
  }

  Future<String> loadOllamaUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ollamaUrlKey) ?? '';
  }

  Future<void> saveOllamaUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ollamaUrlKey, url);
  }

  Future<String> loadOllamaModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ollamaModelKey) ?? '';
  }

  Future<void> saveOllamaModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ollamaModelKey, model);
  }

  Future<String> loadGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiModelKey) ?? '';
  }

  Future<void> saveGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, model);
  }

  Future<String> loadGroqModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groqModelKey) ?? '';
  }

  Future<void> saveGroqModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groqModelKey, model);
  }

  Future<String> loadOpenRouterModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openRouterModelKey) ?? '';
  }

  Future<void> saveOpenRouterModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openRouterModelKey, model);
  }

  Future<OnboardingPreferences?> loadOnboardingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personalizationKey);
    if (raw == null) return null;
    try {
      return OnboardingPreferences.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_personalizationKey, prefs.encode());
    await sp.setBool(_personalizationDoneKey, prefs.isComplete);
  }

  Future<bool> isPersonalizationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_personalizationDoneKey) ?? false;
  }

  Future<void> setPersonalizationComplete({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_personalizationDoneKey, value);
  }

  Future<bool> isFirstRunComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunCompleteKey) ?? false;
  }

  Future<void> setFirstRunComplete({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunCompleteKey, value);
  }

  Future<void> clearOnboardingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_personalizationKey);
    await prefs.remove(_personalizationDoneKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
