import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/settings/get_settings_usecase.dart';
import '../../../domain/usecases/settings/save_settings_usecase.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase _getSettings;
  final SaveSettingsUseCase _saveSettings;

  SettingsCubit({
    required GetSettingsUseCase getSettings,
    required SaveSettingsUseCase saveSettings,
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        super(SettingsState.initial());

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final settings = await _getSettings();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> updateInterval(int intervalSeconds) async {
    final updated = state.settings.copyWith(
      locationIntervalSeconds: intervalSeconds,
    );
    try {
      await _saveSettings(updated);
      emit(state.copyWith(settings: updated));
    } catch (e) {
      emit(state.copyWith(
          error: 'Failed to save settings: ${e.toString()}'));
    }
  }

  Future<void> updateMinMovement(double meters) async {
    final updated = state.settings.copyWith(
      minMovementMeters: meters,
    );
    try {
      await _saveSettings(updated);
      emit(state.copyWith(settings: updated));
    } catch (e) {
      emit(state.copyWith(
          error: 'Failed to save settings: ${e.toString()}'));
    }
  }
}
