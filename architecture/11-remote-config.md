# Remote Configuration

## Strategy

Use **Firebase Remote Config** for all runtime-configurable values. No feature should require an app store update to enable/disable/configure.

## Config Keys

```dart
class RemoteConfigKeys {
  // Feature flags
  static const voiceEnabled = 'voice_enabled';
  static const visionEnabled = 'vision_enabled';
  static const learnEnabled = 'learn_enabled';
  static const agentsEnabled = 'agents_enabled';
  static const businessToolsEnabled = 'business_tools_enabled';

  // Prompt templates (remotely editable, no app update needed)
  static const systemPromptTemplate = 'system_prompt_template';
  static const studyPromptTemplate = 'study_prompt_template';
  static const businessPromptTemplate = 'business_prompt_template';

  // Provider configuration
  static const enabledProviders = 'enabled_providers';        // JSON array
  static const defaultProvider = 'default_provider';
  static const providerOrder = 'provider_order';              // Fallback chain

  // Model routing
  static const simpleChatModel = 'simple_chat_model';
  static const complexModel = 'complex_model';
  static const visionModel = 'vision_model';
  static const codeModel = 'code_model';

  // Cost management
  static const monthlyFreeLimit = 'monthly_free_limit';       // tokens
  static const rateLimitPerMinute = 'rate_limit_per_minute';

  // Maintenance
  static const maintenanceMode = 'maintenance_mode';
  static const maintenanceMessage = 'maintenance_message';
  static const minAppVersion = 'min_app_version';

  // Experimental
  static const experimentalFeatures = 'experimental_features'; // JSON array
}

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  Future<void> initialize() async {
    await _remoteConfig.setDefaults({
      RemoteConfigKeys.voiceEnabled: false,
      RemoteConfigKeys.visionEnabled: false,
      // ... all defaults
    });
    await _remoteConfig.fetchAndActivate();
  }

  bool isFeatureEnabled(String key) => _remoteConfig.getBool(key);

  String getString(String key) => _remoteConfig.getString(key);

  List<String> getStringList(String key) {
    final raw = _remoteConfig.getString(key);
    return (jsonDecode(raw) as List).cast<String>();
  }

  // Listen for real-time config changes
  Stream<RemoteConfigUpdate> get onConfigUpdate =>
      FirebaseRemoteConfig.instance.onConfigUpdated;
}
```

## When to Use Remote Config vs. App Update

| Change Type | Remote Config | App Update |
|------------|---------------|------------|
| Feature flag (on/off) | Yes | No |
| Prompt text | Yes | No |
| API endpoint URL | Yes | No |
| Provider list | Yes | No |
| Rate limits | Yes | No |
| UI layout changes | No | Yes |
| New screen/feature | No | Yes |
| SDK/API changes | No | Yes |
