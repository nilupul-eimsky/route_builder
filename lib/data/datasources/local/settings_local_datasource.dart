import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/app_settings_model.dart';

class SettingsLocalDatasource {
  final SharedPreferences _prefs;

  static const String _intervalKey = 'location_interval_seconds';
  static const String _minMovementKey = 'min_movement_meters';

  SettingsLocalDatasource(this._prefs);

  Future<AppSettingsModel> getSettings() async {
    final interval =
        _prefs.getInt(_intervalKey) ?? AppConstants.defaultIntervalSeconds;
    final minMovement =
        _prefs.getDouble(_minMovementKey) ?? AppConstants.defaultMinMovementMeters;
    return AppSettingsModel(
      locationIntervalSeconds: interval,
      minMovementMeters: minMovement,
    );
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    await _prefs.setInt(_intervalKey, settings.locationIntervalSeconds);
    await _prefs.setDouble(_minMovementKey, settings.minMovementMeters);
  }
}
