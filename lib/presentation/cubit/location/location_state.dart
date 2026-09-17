import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied(
      {this.message = 'Location permission denied.'});

  @override
  List<Object?> get props => [message];
}

class LocationPermissionPermanentlyDenied extends LocationState {
  final String message;

  const LocationPermissionPermanentlyDenied(
      {this.message =
          'Location permission permanently denied. Please enable in settings.'});

  @override
  List<Object?> get props => [message];
}

class LocationServicesDisabled extends LocationState {
  const LocationServicesDisabled();
}

class LocationReady extends LocationState {
  final double latitude;
  final double longitude;

  const LocationReady({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
