import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_settings_entity.dart';

class SettingsState extends Equatable {
  final AppSettingsEntity settings;
  final bool isLoading;
  final String? error;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      settings: AppSettingsEntity.defaults,
      isLoading: false,
    );
  }

  SettingsState copyWith({
    AppSettingsEntity? settings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, error];
}
