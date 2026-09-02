import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

enum SettingsStatus { initial, loading, loaded, saving, error }

final class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings settings;
  final String? exportData;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const AppSettings(),
    this.exportData,
    this.errorMessage,
  });

  const SettingsState.initial() : this();

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    String? exportData,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      exportData: exportData ?? this.exportData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, exportData, errorMessage];
}
