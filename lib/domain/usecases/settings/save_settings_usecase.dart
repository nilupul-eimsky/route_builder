import '../../entities/app_settings_entity.dart';
import '../../repositories/settings_repository.dart';

class SaveSettingsUseCase {
  final SettingsRepository _repository;

  SaveSettingsUseCase(this._repository);

  Future<void> call(AppSettingsEntity settings) async {
    await _repository.saveSettings(settings);
  }
}
