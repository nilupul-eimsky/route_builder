import '../../../core/utils/distance_calculator.dart';
import '../../entities/gps_point_entity.dart';
import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class AddGpsPointUseCase {
  final TrackingRepository _repository;

  AddGpsPointUseCase(this._repository);

  Future<TrackingSessionEntity> call(
    TrackingSessionEntity session,
    GpsPointEntity newPoint,
  ) async {
    // Calculate additional distance from last point
    double additionalDistance = 0.0;
    if (session.points.isNotEmpty) {
      final lastPoint = session.points.last;
      additionalDistance = DistanceCalculator.betweenLatLng(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );
    }

    final updatedPoints = List<GpsPointEntity>.from(session.points)
      ..add(newPoint);

    final updatedSession = session.copyWith(
      points: updatedPoints,
      totalDistanceMeters: session.totalDistanceMeters + additionalDistance,
    );

    // Persist BEFORE updating UI state
    await _repository.saveSession(updatedSession);
    return updatedSession;
  }
}
