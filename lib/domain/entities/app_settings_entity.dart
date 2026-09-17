import 'package:equatable/equatable.dart';

class AppSettingsEntity extends Equatable {
  /// Location recording interval in seconds.
  /// Allowed values: 1, 5, 10, 15, 30, 60, 300
  final int locationIntervalSeconds;

  /// Minimum movement in meters before a GPS point is recorded.
  /// Allowed values: 10, 50, 100, 200, 500
  final double minMovementMeters;

  const AppSettingsEntity({
    required this.locationIntervalSeconds,
    this.minMovementMeters = 100.0,
  });

  static const AppSettingsEntity defaults = AppSettingsEntity(
    locationIntervalSeconds: 5,
    minMovementMeters: 100.0,
  );

  @override
  List<Object?> get props => [locationIntervalSeconds, minMovementMeters];

  AppSettingsEntity copyWith({
    int? locationIntervalSeconds,
    double? minMovementMeters,
  }) {
    return AppSettingsEntity(
      locationIntervalSeconds:
          locationIntervalSeconds ?? this.locationIntervalSeconds,
      minMovementMeters: minMovementMeters ?? this.minMovementMeters,
    );
  }

  @override
  String toString() =>
      'AppSettingsEntity(intervalSeconds: $locationIntervalSeconds, minMovement: ${minMovementMeters}m)';
}
