import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/accent_theme.dart';
import '../../domain/entities/app_settings.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

final class UpdateTheme extends SettingsEvent {
  final ThemeMode theme;
  const UpdateTheme(this.theme);

  @override
  List<Object?> get props => [theme];
}

final class UpdateLanguage extends SettingsEvent {
  final String language;
  const UpdateLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

final class UpdateAiProvider extends SettingsEvent {
  final AiProviderOption provider;
  const UpdateAiProvider(this.provider);

  @override
  List<Object?> get props => [provider];
}

final class UpdateMemoryEnabled extends SettingsEvent {
  final bool enabled;
  const UpdateMemoryEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class UpdateAnalyticsEnabled extends SettingsEvent {
  final bool enabled;
  const UpdateAnalyticsEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class UpdateSaveChatHistory extends SettingsEvent {
  final bool enabled;
  const UpdateSaveChatHistory(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class UpdateAllowTraining extends SettingsEvent {
  final bool enabled;
  const UpdateAllowTraining(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

final class ExportDataRequested extends SettingsEvent {
  final String uid;
  const ExportDataRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}

final class DeleteAccountDataRequested extends SettingsEvent {
  final String uid;
  const DeleteAccountDataRequested(this.uid);
  @override
  List<Object?> get props => [uid];
}
final class UpdateAccentTheme extends SettingsEvent {
  final AccentTheme accentTheme;
  const UpdateAccentTheme(this.accentTheme);
  @override
  List<Object?> get props => [accentTheme];
}
final class UpdateAccentIntensity extends SettingsEvent {
  final AccentIntensity intensity;
  const UpdateAccentIntensity(this.intensity);
  @override
  List<Object?> get props => [intensity];
}
