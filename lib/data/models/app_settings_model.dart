import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    required super.locationIntervalSeconds,
    super.minMovementMeters = AppConstants.defaultMinMovementMeters,
  });

  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      locationIntervalSeconds: entity.locationIntervalSeconds,
      minMovementMeters: entity.minMovementMeters,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      locationIntervalSeconds: json['locationIntervalSeconds'] as int,
      minMovementMeters: (json['minMovementMeters'] as num?)?.toDouble() ??
          AppConstants.defaultMinMovementMeters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationIntervalSeconds': locationIntervalSeconds,
      'minMovementMeters': minMovementMeters,
    };
  }
}
