import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(const LocationInitial());

  Future<void> checkPermission() async {
    emit(const LocationLoading());
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationServicesDisabled());
        return;
      }

      final permission = await Geolocator.checkPermission();
      _handlePermission(permission);
    } catch (e) {
      emit(LocationPermissionDenied(message: e.toString()));
    }
  }

  Future<void> requestPermission() async {
    emit(const LocationLoading());
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationServicesDisabled());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _handlePermission(permission);
    } catch (e) {
      emit(LocationPermissionDenied(message: e.toString()));
    }
  }

  Future<void> getCurrentLocation() async {
    emit(const LocationLoading());
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationServicesDisabled());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        emit(const LocationPermissionDenied());
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const LocationPermissionPermanentlyDenied());
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      emit(LocationReady(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      emit(LocationPermissionDenied(message: e.toString()));
    }
  }

  void _handlePermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        emit(const LocationPermissionDenied());
        break;
      case LocationPermission.deniedForever:
        emit(const LocationPermissionPermanentlyDenied());
        break;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        emit(const LocationReady(latitude: 0.0, longitude: 0.0));
        break;
      case LocationPermission.unableToDetermine:
        emit(const LocationPermissionDenied(
            message: 'Unable to determine location permission.'));
        break;
    }
  }
}
