import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../domain/entities/tracking_session_entity.dart';
import '../../models/tracking_session_model.dart';

class TrackingLocalDatasource {
  final Box<String> _box;

  TrackingLocalDatasource(this._box);

  Future<void> saveSession(TrackingSessionModel session) async {
    await _box.put(session.id, jsonEncode(session.toJson()));
  }

  Future<List<TrackingSessionModel>> getSessionsForRoute(
      String routeId) async {
    return _box.values
        .map((json) => TrackingSessionModel.fromJson(
            jsonDecode(json) as Map<String, dynamic>))
        .where((session) => session.routeId == routeId)
        .toList();
  }

  Future<TrackingSessionModel?> getSession(String id) async {
    final json = _box.get(id);
    if (json == null) return null;
    return TrackingSessionModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> deleteSessionsForRoute(String routeId) async {
    final keysToDelete = _box.keys.where((key) {
      final json = _box.get(key as String);
      if (json == null) return false;
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['routeId'] == routeId;
      } catch (_) {
        return false;
      }
    }).toList();

    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<TrackingSessionModel?> getUnfinishedSession() async {
    for (final json in _box.values) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final status = map['status'] as String?;
        if (status == TrackingStatus.tracking.name ||
            status == TrackingStatus.paused.name) {
          return TrackingSessionModel.fromJson(map);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
