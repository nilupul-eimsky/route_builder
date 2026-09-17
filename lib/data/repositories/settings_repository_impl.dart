import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;

  SettingsRepositoryImpl(this._datasource);

  @override
  Future<AppSettingsEntity> getSettings() async {
    return _datasource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettingsEntity settings) async {
    final model = AppSettingsModel.fromEntity(settings);
    await _datasource.saveSettings(model);
  }
}
