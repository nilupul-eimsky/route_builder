import '../../entities/app_settings_entity.dart';
import '../../repositories/settings_repository.dart';

class GetSettingsUseCase {
  final SettingsRepository _repository;

  GetSettingsUseCase(this._repository);

  Future<AppSettingsEntity> call() async {
    return _repository.getSettings();
  }
}
