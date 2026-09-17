import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/app_settings_entity.dart';
import '../../../domain/entities/gps_point_entity.dart';
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/entities/tracking_session_entity.dart';
import '../../../domain/usecases/tracking/add_gps_point_usecase.dart';
import '../../../domain/usecases/tracking/add_stop_usecase.dart';
import '../../../domain/usecases/tracking/pause_tracking_usecase.dart';
import '../../../domain/usecases/tracking/resume_tracking_usecase.dart';
import '../../../domain/usecases/tracking/start_tracking_usecase.dart';
import '../../../domain/usecases/tracking/stop_tracking_usecase.dart';
import '../../../domain/usecases/tracking/validate_gps_point_usecase.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final StartTrackingUseCase _startTracking;
  final StopTrackingUseCase _stopTracking;
  final PauseTrackingUseCase _pauseTracking;
  final ResumeTrackingUseCase _resumeTracking;
  final AddGpsPointUseCase _addGpsPoint;
  final ValidateGpsPointUseCase _validateGpsPoint;
  final AddStopUseCase _addStop;

  StreamSubscription<Position>? _positionSubscription;
  int _intervalSeconds = 5;
  double _minMovementMeters = 100.0;
  final Uuid _uuid = const Uuid();

  TrackingBloc({
    required StartTrackingUseCase startTracking,
    required StopTrackingUseCase stopTracking,
    required PauseTrackingUseCase pauseTracking,
    required ResumeTrackingUseCase resumeTracking,
    required AddGpsPointUseCase addGpsPoint,
    required ValidateGpsPointUseCase validateGpsPoint,
    required AddStopUseCase addStop,
  })  : _startTracking = startTracking,
        _stopTracking = stopTracking,
        _pauseTracking = pauseTracking,
        _resumeTracking = resumeTracking,
        _addGpsPoint = addGpsPoint,
        _validateGpsPoint = validateGpsPoint,
        _addStop = addStop,
        super(const TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<PauseTracking>(_onPauseTracking);
    on<ResumeTracking>(_onResumeTracking);
    on<StopTracking>(_onStopTracking);
    on<GpsUpdate>(_onGpsUpdate);
    on<RestoreSession>(_onRestoreSession);
    on<AddStop>(_onAddStop);
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();

    late LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GPS Tracking Active',
          notificationText: 'Route Builder is recording your GPS track.',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => add(GpsUpdate(position)),
      onError: (Object error) {
        add(const StopTracking());
      },
    );
  }

  Future<void> _onStartTracking(
      StartTracking event, Emitter<TrackingState> emit) async {
    // Only one active tracking session at a time
    if (state is TrackingActive || state is TrackingPaused) {
      return;
    }

    // Verify location services and permission before starting
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const TrackingError(
          'Location services are disabled. Please enable them in settings.'));
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      emit(const TrackingError(
          'Location permission is required for tracking.'));
      return;
    }

    try {
      _intervalSeconds = event.settings.locationIntervalSeconds;
      _minMovementMeters = event.settings.minMovementMeters;
      final session = await _startTracking(event.routeId);

      // Use last known position for an immediate map pin while the stream warms up
      Position? last;
      try {
        last = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      emit(TrackingActive(
        session: session,
        currentLatitude: last?.latitude ?? 0.0,
        currentLongitude: last?.longitude ?? 0.0,
        accuracy: last?.accuracy ?? 0.0,
      ));
      _startPositionStream();
    } catch (e) {
      emit(TrackingError('Failed to start tracking: ${e.toString()}'));
    }
  }

  Future<void> _onPauseTracking(
      PauseTracking event, Emitter<TrackingState> emit) async {
    final currentState = state;
    if (currentState is TrackingActive) {
      try {
        final paused = await _pauseTracking(currentState.session);
        _positionSubscription?.cancel();
        _positionSubscription = null;
        emit(TrackingPaused(
          session: paused,
          currentLatitude: currentState.currentLatitude,
          currentLongitude: currentState.currentLongitude,
          accuracy: currentState.accuracy,
        ));
      } catch (e) {
        emit(TrackingError('Failed to pause: ${e.toString()}'));
      }
    }
  }

  Future<void> _onResumeTracking(
      ResumeTracking event, Emitter<TrackingState> emit) async {
    final currentState = state;
    if (currentState is TrackingPaused) {
      try {
        final resumed = await _resumeTracking(currentState.session);
        emit(TrackingActive(
          session: resumed,
          currentLatitude: currentState.currentLatitude,
          currentLongitude: currentState.currentLongitude,
          accuracy: currentState.accuracy,
        ));
        _startPositionStream();
      } catch (e) {
        emit(TrackingError('Failed to resume: ${e.toString()}'));
      }
    }
  }

  Future<void> _onStopTracking(
      StopTracking event, Emitter<TrackingState> emit) async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    final currentState = state;
    TrackingSessionEntity? session;
    if (currentState is TrackingActive) {
      session = currentState.session;
    } else if (currentState is TrackingPaused) {
      session = currentState.session;
    }

    if (session != null) {
      try {
        final completed = await _stopTracking(session);
        emit(TrackingCompleted(completed));
      } catch (e) {
        emit(TrackingError('Failed to stop tracking: ${e.toString()}'));
      }
    } else {
      emit(const TrackingInitial());
    }
  }

  Future<void> _onGpsUpdate(
      GpsUpdate event, Emitter<TrackingState> emit) async {
    final currentState = state;
    if (currentState is! TrackingActive) return;

    final position = event.position;
    final session = currentState.session;

    final lastPoint =
        session.points.isNotEmpty ? session.points.last : null;
    final lastRecordedAt = currentState.lastRecordedAt;

    // Always update the raw GPS location for display
    final isValid = _validateGpsPoint(
      newLatitude: position.latitude,
      newLongitude: position.longitude,
      accuracy: position.accuracy,
      lastStoredPoint: lastPoint,
      lastRecordedTime: lastRecordedAt,
      intervalSeconds: _intervalSeconds,
      minMovementMeters: _minMovementMeters,
    );

    if (isValid) {
      // Persist point BEFORE updating UI state
      final newPoint = GpsPointEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp.toUtc(),
        accuracy: position.accuracy,
        speed: position.speed < 0 ? 0.0 : position.speed,
        altitude: position.altitude,
      );

      try {
        final updatedSession = await _addGpsPoint(session, newPoint);
        emit(TrackingActive(
          session: updatedSession,
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          accuracy: position.accuracy,
          lastRecordedAt: DateTime.now(),
        ));
      } catch (e) {
        // Point persistence failed; update display position only
        emit(currentState.copyWith(
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          accuracy: position.accuracy,
        ));
      }
    } else {
      // Not valid to record; just update display position
      emit(currentState.copyWith(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        accuracy: position.accuracy,
      ));
    }
  }

  Future<void> _onRestoreSession(
      RestoreSession event, Emitter<TrackingState> emit) async {
    final session = event.session;
    final lastPoint =
        session.points.isNotEmpty ? session.points.last : null;

    if (session.status == TrackingStatus.tracking) {
      emit(TrackingActive(
        session: session,
        currentLatitude: lastPoint?.latitude ?? 0.0,
        currentLongitude: lastPoint?.longitude ?? 0.0,
        accuracy: lastPoint?.accuracy ?? 0.0,
      ));
      _startPositionStream();
    } else if (session.status == TrackingStatus.paused) {
      emit(TrackingPaused(
        session: session,
        currentLatitude: lastPoint?.latitude ?? 0.0,
        currentLongitude: lastPoint?.longitude ?? 0.0,
        accuracy: lastPoint?.accuracy ?? 0.0,
      ));
    }
  }

  Future<void> _onAddStop(AddStop event, Emitter<TrackingState> emit) async {
    final currentState = state;

    TrackingSessionEntity? session;
    double lat = 0.0, lng = 0.0, accuracy = 0.0;
    bool wasActive = false;

    if (currentState is TrackingActive) {
      session = currentState.session;
      lat = currentState.currentLatitude;
      lng = currentState.currentLongitude;
      accuracy = currentState.accuracy;
      wasActive = true;
    } else if (currentState is TrackingPaused) {
      session = currentState.session;
      lat = currentState.currentLatitude;
      lng = currentState.currentLongitude;
      accuracy = currentState.accuracy;
    }

    if (session == null) return;

    final stop = RouteStopEntity(
      id: _uuid.v4(),
      name: event.stopName,
      latitude: lat,
      longitude: lng,
      recordedAt: DateTime.now().toUtc(),
    );

    try {
      // Add stop and persist to storage
      final sessionWithStop = await _addStop(session, stop);

      if (wasActive) {
        // Cancel position stream and pause the session
        _positionSubscription?.cancel();
        _positionSubscription = null;
        final pausedSession = await _pauseTracking(sessionWithStop);
        emit(TrackingPaused(
          session: pausedSession,
          currentLatitude: lat,
          currentLongitude: lng,
          accuracy: accuracy,
        ));
      } else {
        // Already paused — just update state with new stop
        emit(TrackingPaused(
          session: sessionWithStop,
          currentLatitude: lat,
          currentLongitude: lng,
          accuracy: accuracy,
        ));
      }
    } catch (e) {
      emit(TrackingError('Failed to add stop: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
