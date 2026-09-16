import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:banataq/core/constants/app_keys.dart';
import 'package:banataq/services/storage_service.dart';
import 'package:banataq/services/assistant_service.dart';
import 'package:banataq/services/secure_key_store.dart';

// In-memory fake to avoid platform channel for flutter_secure_storage.
class FakeSecureKeyStore extends SecureKeyStore {
  final Map<String, String> _map = {};
  @override
  Future<String?> readGemini() async => _map['gemini_api_key'];
  @override
  Future<String?> readGroq() async => _map['groq_api_key'];
  @override
  Future<String?> readOpenRouter() async => _map['openrouter_api_key'];
  @override
  Future<String?> readOpenAI() async => _map['openai_api_key'];
  @override
  Future<void> writeGemini(String v) async => _map['gemini_api_key'] = v;
  @override
  Future<void> writeGroq(String v) async => _map['groq_api_key'] = v;
  @override
  Future<void> writeOpenRouter(String v) async => _map['openrouter_api_key'] = v;
  @override
  Future<void> writeOpenAI(String v) async => _map['openai_api_key'] = v;
  @override
  Future<void> delete(String key) async => _map.remove(key);

  bool contains(String key) => _map.containsKey(key);
  String? get(String key) => _map[key];
}

class _ThrowingSecureStore extends SecureKeyStore {
  @override
  Future<void> writeGroq(String v) async => throw Exception('secure write failed');
  @override
  Future<void> writeGemini(String v) async => throw Exception('secure write failed');
  @override
  Future<void> writeOpenRouter(String v) async => throw Exception('secure write failed');
  @override
  Future<void> writeOpenAI(String v) async => throw Exception('secure write failed');
  @override
  Future<String?> readGroq() async => null;
  @override
  Future<String?> readGemini() async => null;
  @override
  Future<String?> readOpenRouter() async => null;
  @override
  Future<String?> readOpenAI() async => null;
}

void main() {
  group('PR1 Gemini catalog', () {
    test('kGeminiModels contains valid IDs and default is valid', () {
      expect(kGeminiModels, isNotEmpty);
      expect(kGeminiModels, contains(kDefaultGeminiModel));
      // Valid IDs verified against Google docs Aug 2026 — these must not 404.
      // We keep the 6 verified IDs (3.7, 3.6, flash-lite-latest, 2.5-flash-lite, 3.1-flash-lite, 3.1-pro-preview)
      expect(kGeminiModels, contains('gemini-3.7-flash'));
      expect(kGeminiModels, contains('gemini-3.6-flash'));
      expect(kGeminiModels, contains('gemini-flash-lite-latest'));
      expect(kGeminiModels.length, 6);
      // No fake placeholders like gemini-3.99-fake
      for (final m in kGeminiModels) {
        expect(m.startsWith('gemini-'), true, reason: 'invalid prefix $m');
      }
    });

    test('GeminiProvider default model is valid and in catalog', () async {
      // storage not needed; check AppKeys catalog directly
      expect(kGeminiModels.contains(kDefaultGeminiModel), isTrue);
    });

    test('AppKeys hasEmbedded flags are false when no baked keys', () {
      expect(AppKeys.hasEmbeddedGeminiKey, isFalse);
      expect(AppKeys.hasEmbeddedGroqKey, isFalse);
      expect(AppKeys.hasEmbeddedOpenRouterKey, isFalse);
      expect(AppKeys.hasEmbeddedOpenaiKey, isFalse);
      expect(AppKeys.geminiApiKey, isEmpty);
      expect(AppKeys.groqApiKey, isEmpty);
    });

    test('kAllFreeModels preserves all providers', () {
      expect(kAllFreeModels, containsAll(kGeminiModels));
      expect(kAllFreeModels, containsAll(kGroqModels));
      expect(kAllFreeModels, containsAll(kOpenRouterModels));
    });
  });

  group('PR1 Secure storage — no plaintext apiKey', () {
    late FakeSecureKeyStore fake;

    setUp(() {
      fake = FakeSecureKeyStore();
      StorageService.setTestSecureStore(fake);
    });

    tearDown(() {
      StorageService.setTestSecureStore(null);
    });

    test('saveAiConfig writes apiKey to SecureKeyStore not SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.saveAiConfig(AiProviderType.groq, 'gsk_test123');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ai_config');
      expect(raw, isNotNull);
      expect(raw, isNot(contains('gsk_test123')), reason: 'apiKey must not be in SharedPreferences');
      expect(raw, contains('groq'));
      expect(raw, isNot(contains('apiKey')));
      expect(fake.get('groq_api_key'), 'gsk_test123');
      // load via secure
      final loaded = await storage.loadAiConfig();
      expect(loaded['apiKey'], 'gsk_test123');
    });

    test('loadAiConfig migration moves legacy apiKey to SecureKeyStore idempotently', () async {
      SharedPreferences.setMockInitialValues({
        'ai_config': '{"provider":"groq","apiKey":"gsk_legacy123"}',
      });
      final storage = StorageService();
      final first = await storage.loadAiConfig();
      expect(first['provider'], AiProviderType.groq);
      expect(first['apiKey'], 'gsk_legacy123');
      expect(fake.get('groq_api_key'), 'gsk_legacy123');
      final prefs = await SharedPreferences.getInstance();
      final rawAfter = prefs.getString('ai_config');
      expect(rawAfter, isNotNull);
      expect(rawAfter, isNot(contains('gsk_legacy123')));
      expect(rawAfter, contains('groq'));
      final second = await storage.loadAiConfig();
      expect(second['apiKey'], 'gsk_legacy123');
      final rawAfter2 = prefs.getString('ai_config');
      expect(rawAfter2, isNot(contains('gsk_legacy123')));
    });

    test('failed migration does not destroy legacy secret', () async {
      SharedPreferences.setMockInitialValues({
        'ai_config': '{"provider":"openai","apiKey":"sk-test-openai"}',
      });
      // Fake that throws on write
      final throwing = _ThrowingSecureStore();
      StorageService.setTestSecureStore(throwing);
      final storage = StorageService();
      final loaded = await storage.loadAiConfig();
      expect(loaded['provider'], AiProviderType.openai);
      expect(loaded['apiKey'], 'sk-test-openai');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ai_config');
      // legacy must still contain secret because migration failed
      expect(raw, contains('sk-test-openai'));
      StorageService.setTestSecureStore(fake);
    });

    test('non-secret preferences still work after migration', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.setOnboardingComplete();
      expect(await storage.isOnboardingComplete(), isTrue);
      await storage.saveOllamaModel('qwen3:1.7b');
      expect(await storage.loadOllamaModel(), 'qwen3:1.7b');
    });
  });
}
