part of 'tracking_bloc.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

class TrackingActive extends TrackingState {
  final TrackingSessionEntity session;
  final double currentLatitude;
  final double currentLongitude;
  final double accuracy;
  final DateTime? lastRecordedAt;

  const TrackingActive({
    required this.session,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.accuracy,
    this.lastRecordedAt,
  });

  @override
  List<Object?> get props => [
        session,
        currentLatitude,
        currentLongitude,
        accuracy,
        lastRecordedAt,
      ];

  TrackingActive copyWith({
    TrackingSessionEntity? session,
    double? currentLatitude,
    double? currentLongitude,
    double? accuracy,
    DateTime? lastRecordedAt,
  }) {
    return TrackingActive(
      session: session ?? this.session,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      accuracy: accuracy ?? this.accuracy,
      lastRecordedAt: lastRecordedAt ?? this.lastRecordedAt,
    );
  }
}

class TrackingPaused extends TrackingState {
  final TrackingSessionEntity session;
  final double currentLatitude;
  final double currentLongitude;
  final double accuracy;

  const TrackingPaused({
    required this.session,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.accuracy,
  });

  @override
  List<Object?> get props => [session, currentLatitude, currentLongitude, accuracy];

  TrackingPaused copyWith({
    TrackingSessionEntity? session,
    double? currentLatitude,
    double? currentLongitude,
    double? accuracy,
  }) {
    return TrackingPaused(
      session: session ?? this.session,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}

class TrackingCompleted extends TrackingState {
  final TrackingSessionEntity session;

  const TrackingCompleted(this.session);

  @override
  List<Object?> get props => [session];
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
