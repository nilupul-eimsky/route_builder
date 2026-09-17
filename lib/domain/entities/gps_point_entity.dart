import 'package:equatable/equatable.dart';

class GpsPointEntity extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double speed;
  final double? altitude;

  const GpsPointEntity({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.speed,
    this.altitude,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        timestamp,
        accuracy,
        speed,
        altitude,
      ];

  @override
  String toString() =>
      'GpsPointEntity(lat: $latitude, lng: $longitude, acc: $accuracy, speed: $speed)';
}
