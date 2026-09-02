import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/accent_theme.dart';

enum AiProviderOption { local, openai, gemini }

extension AiProviderOptionLabel on AiProviderOption {
  String get label {
    return switch (this) {
      AiProviderOption.local => 'Local (offline)',
      AiProviderOption.openai => 'OpenAI',
      AiProviderOption.gemini => 'Google Gemini',
    };
  }
}

final class AppSettings extends Equatable {
  final ThemeMode theme;
  final AccentTheme accentTheme;
  final AccentIntensity accentIntensity;
  final String language;
  final AiProviderOption defaultAiProvider;
  final bool memoryEnabled;
  final bool analyticsEnabled;
  final bool saveChatHistory;
  final bool allowTraining;

  const AppSettings({
    this.theme = ThemeMode.system,
    this.accentTheme = AccentTheme.royalBlue,
    this.accentIntensity = AccentIntensity.balanced,
    this.language = 'en',
    this.defaultAiProvider = AiProviderOption.local,
    this.memoryEnabled = false,
    this.analyticsEnabled = true,
    this.saveChatHistory = true,
    this.allowTraining = false,
  });

  AppSettings copyWith({
    ThemeMode? theme,
    AccentTheme? accentTheme,
    AccentIntensity? accentIntensity,
    String? language,
    AiProviderOption? defaultAiProvider,
    bool? memoryEnabled,
    bool? analyticsEnabled,
    bool? saveChatHistory,
    bool? allowTraining,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accentTheme: accentTheme ?? this.accentTheme,
      accentIntensity: accentIntensity ?? this.accentIntensity,
      language: language ?? this.language,
      defaultAiProvider: defaultAiProvider ?? this.defaultAiProvider,
      memoryEnabled: memoryEnabled ?? this.memoryEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      saveChatHistory: saveChatHistory ?? this.saveChatHistory,
      allowTraining: allowTraining ?? this.allowTraining,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'accentTheme': accentTheme.name,
        'accentIntensity': accentIntensity.name,
        'language': language,
        'defaultAiProvider': defaultAiProvider.name,
        'memoryEnabled': memoryEnabled,
        'analyticsEnabled': analyticsEnabled,
        'saveChatHistory': saveChatHistory,
        'allowTraining': allowTraining,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: ThemeMode.values.firstWhere((e) => e.name == json['theme'], orElse: () => ThemeMode.system),
      accentTheme: AccentTheme.values.firstWhere((e) => e.name == json['accentTheme'], orElse: () => AccentTheme.royalBlue),
      accentIntensity: AccentIntensity.values.firstWhere((e) => e.name == json['accentIntensity'], orElse: () => AccentIntensity.balanced),
      language: json['language'] as String? ?? 'en',
      defaultAiProvider: AiProviderOption.values.firstWhere((e) => e.name == json['defaultAiProvider'], orElse: () => AiProviderOption.local),
      memoryEnabled: json['memoryEnabled'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      saveChatHistory: json['saveChatHistory'] as bool? ?? true,
      allowTraining: json['allowTraining'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [theme, accentTheme, accentIntensity, language, defaultAiProvider, memoryEnabled, analyticsEnabled, saveChatHistory, allowTraining];
}
