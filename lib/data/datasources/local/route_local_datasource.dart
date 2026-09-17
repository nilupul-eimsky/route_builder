import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/route_model.dart';

class RouteLocalDatasource {
  final Box<String> _box;

  RouteLocalDatasource(this._box);

  Future<void> saveRoute(RouteModel route) async {
    await _box.put(route.id, jsonEncode(route.toJson()));
  }

  Future<List<RouteModel>> getAllRoutes() async {
    return _box.values
        .map((json) =>
            RouteModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<RouteModel?> getRoute(String id) async {
    final json = _box.get(id);
    if (json == null) return null;
    return RouteModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> deleteRoute(String id) async {
    await _box.delete(id);
  }
}
