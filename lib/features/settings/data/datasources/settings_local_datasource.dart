import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';
import '../../../../core/errors/app_result.dart';
import '../../../../core/errors/app_error.dart';

final class SettingsLocalDataSource {
  final SharedPreferences _prefs;

  SettingsLocalDataSource(this._prefs);

  static const _settingsKey = 'app_settings_v2';
  static const _openaiKeyKey = 'openai_api_key';
  static const _geminiKeyKey = 'gemini_api_key';

  Future<AppResult<AppSettings>> getSettings() async {
    try {
      final raw = _prefs.getString(_settingsKey);
      if (raw == null) {
        return const Success(AppSettings());
      }
      return Success(AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (e) {
      return Failure(CacheError('Failed to load settings: $e'));
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveApiKey(AiProviderOption provider, String key) async {
    final storageKey = switch (provider) {
      AiProviderOption.openai => _openaiKeyKey,
      AiProviderOption.gemini => _geminiKeyKey,
      AiProviderOption.local => null,
    };
    if (storageKey != null) {
      await _prefs.setString(storageKey, key);
    }
  }

  Future<String?> getApiKey(AiProviderOption provider) async {
    final storageKey = switch (provider) {
      AiProviderOption.openai => _openaiKeyKey,
      AiProviderOption.gemini => _geminiKeyKey,
      AiProviderOption.local => null,
    };
    if (storageKey == null) return null;
    return _prefs.getString(storageKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_openaiKeyKey);
    await _prefs.remove(_geminiKeyKey);
  }
}
