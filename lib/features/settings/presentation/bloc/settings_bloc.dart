import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import '../../domain/usecases/export_data.dart';
import '../../domain/usecases/delete_account_data.dart';
import '../../../../core/errors/app_result.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;
  final ExportData exportData;
  final DeleteAccountData deleteAccountData;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
    required this.exportData,
    required this.deleteAccountData,
  }) : super(const SettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateAccentTheme>(_onUpdateAccentTheme);
    on<UpdateAccentIntensity>(_onUpdateAccentIntensity);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateAiProvider>(_onUpdateAiProvider);
    on<UpdateMemoryEnabled>(_onUpdateMemoryEnabled);
    on<UpdateAnalyticsEnabled>(_onUpdateAnalyticsEnabled);
    on<UpdateSaveChatHistory>(_onUpdateSaveChatHistory);
    on<UpdateAllowTraining>(_onUpdateAllowTraining);
    on<ExportDataRequested>(_onExportData);
    on<DeleteAccountDataRequested>(_onDeleteAccountData);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await getSettings();
    if (result is Success<AppSettings>) {
      emit(state.copyWith(status: SettingsStatus.loaded, settings: result.data));
    } else {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }

  Future<void> _saveAndEmit(SettingsEvent event, Emitter<SettingsState> emit, AppSettings updated) async {
    // Apply the change immediately so toggles (theme, language, etc.) feel
    // instant; persist in the background. A slow/failed remote sync must
    // never block the UI.
    emit(state.copyWith(status: SettingsStatus.loaded, settings: updated));
    final result = await updateSettings(updated);
    if (result is Failure<AppSettings>) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }

  Future<void> _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(theme: event.theme));
  }
  Future<void> _onUpdateAccentTheme(UpdateAccentTheme event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(accentTheme: event.accentTheme));
  }
  Future<void> _onUpdateAccentIntensity(UpdateAccentIntensity event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(accentIntensity: event.intensity));
  }

  Future<void> _onUpdateLanguage(UpdateLanguage event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(language: event.language));
  }

  Future<void> _onUpdateAiProvider(UpdateAiProvider event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(defaultAiProvider: event.provider));
  }

  Future<void> _onUpdateMemoryEnabled(UpdateMemoryEnabled event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(memoryEnabled: event.enabled));
  }

  Future<void> _onUpdateAnalyticsEnabled(UpdateAnalyticsEnabled event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(analyticsEnabled: event.enabled));
  }

  Future<void> _onUpdateSaveChatHistory(UpdateSaveChatHistory event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(saveChatHistory: event.enabled));
  }

  Future<void> _onUpdateAllowTraining(UpdateAllowTraining event, Emitter<SettingsState> emit) async {
    await _saveAndEmit(event, emit, state.settings.copyWith(allowTraining: event.enabled));
  }

  Future<void> _onExportData(ExportDataRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await exportData(event.uid);
    if (result is Success<String>) {
      emit(state.copyWith(status: SettingsStatus.loaded, exportData: result.data));
    } else {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }

  Future<void> _onDeleteAccountData(DeleteAccountDataRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await deleteAccountData(event.uid);
    if (result is Success<void>) {
      emit(state.copyWith(status: SettingsStatus.loaded));
    } else {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }
}
