part of 'tracking_bloc.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class StartTracking extends TrackingEvent {
  final String routeId;
  final AppSettingsEntity settings;

  const StartTracking({required this.routeId, required this.settings});

  @override
  List<Object?> get props => [routeId, settings];
}

class PauseTracking extends TrackingEvent {
  const PauseTracking();
}

class ResumeTracking extends TrackingEvent {
  const ResumeTracking();
}

class StopTracking extends TrackingEvent {
  const StopTracking();
}

class GpsUpdate extends TrackingEvent {
  final Position position;

  const GpsUpdate(this.position);

  @override
  List<Object?> get props => [position];
}

class RestoreSession extends TrackingEvent {
  final TrackingSessionEntity session;

  const RestoreSession(this.session);

  @override
  List<Object?> get props => [session];
}

class AddStop extends TrackingEvent {
  final String stopName;

  const AddStop(this.stopName);

  @override
  List<Object?> get props => [stopName];
}
