import 'package:flutter/foundation.dart';

import '../../features/teleprompter/data/datasources/key_value_store.dart';
import '../../features/teleprompter/data/datasources/script_local_data_source.dart';
import '../../features/teleprompter/data/datasources/settings_local_data_source.dart';
import '../../features/teleprompter/data/repositories/script_repository_impl.dart';
import '../../features/teleprompter/data/repositories/settings_repository_impl.dart';
import '../../features/teleprompter/domain/repositories/script_repository.dart';
import '../../features/teleprompter/domain/repositories/settings_repository.dart';
import '../../features/teleprompter/domain/usecases/script_usecases.dart';
import '../../features/teleprompter/domain/usecases/settings_usecases.dart';
import '../services/keep_awake_service.dart';
import '../services/screen_recording_service.dart';

/// Composition root.
///
/// Built once during startup and injected with `RepositoryProvider`, so every
/// widget can reach a use case without a service locator and without knowing
/// how storage is implemented. Use-case getters are cheap to call — they are
/// thin, stateless wrappers around the repositories.
class AppDependencies {
  const AppDependencies({
    required this.scriptRepository,
    required this.teleprompterSettingsRepository,
    required this.appSettingsRepository,
    this.keepAwakeService = const ScreenKeepAwakeService(),
    this.recordingService,
  });

  final ScriptRepository scriptRepository;
  final TeleprompterSettingsRepository teleprompterSettingsRepository;
  final AppSettingsRepository appSettingsRepository;
  final KeepAwakeService keepAwakeService;
  final ScreenRecordingService? recordingService;

  /// Opens local storage and wires the object graph.
  ///
  /// Storage failures are non-fatal: the app falls back to an in-memory store so
  /// it always launches, it just will not remember anything after a restart.
  static Future<AppDependencies> bootstrap() async {
    KeyValueStore store;
    try {
      store = await SharedPreferencesStore.open();
    } catch (error, stackTrace) {
      debugPrint('Storage unavailable, continuing in memory: $error\n$stackTrace');
      store = InMemoryKeyValueStore();
    }

    return AppDependencies(
      scriptRepository: ScriptRepositoryImpl(ScriptLocalDataSourceImpl(store)),
      teleprompterSettingsRepository: TeleprompterSettingsRepositoryImpl(
        TeleprompterSettingsLocalDataSourceImpl(store),
      ),
      appSettingsRepository: AppSettingsRepositoryImpl(
        AppSettingsLocalDataSourceImpl(store),
      ),
      recordingService: ScreenRecordingService(),
    );
  }

  // --- Script use cases -----------------------------------------------------
  GetScripts get getScripts => GetScripts(scriptRepository);
  GetScript get getScript => GetScript(scriptRepository);
  SaveScript get saveScript => SaveScript(scriptRepository);
  DeleteScript get deleteScript => DeleteScript(scriptRepository);
  DuplicateScript get duplicateScript => DuplicateScript(scriptRepository);

  // --- Settings use cases ---------------------------------------------------
  GetTeleprompterSettings get getTeleprompterSettings =>
      GetTeleprompterSettings(teleprompterSettingsRepository);
  SaveTeleprompterSettings get saveTeleprompterSettings =>
      SaveTeleprompterSettings(teleprompterSettingsRepository);
  ResetTeleprompterSettings get resetTeleprompterSettings =>
      ResetTeleprompterSettings(teleprompterSettingsRepository);
  GetAppSettings get getAppSettings => GetAppSettings(appSettingsRepository);
  SaveAppSettings get saveAppSettings => SaveAppSettings(appSettingsRepository);
  ResetAppSettings get resetAppSettings => ResetAppSettings(appSettingsRepository);

  /// Only used by tests, which need a deterministic, isolated store.
  @visibleForTesting
  static Future<AppDependencies> withStore(KeyValueStore store) async {
    return AppDependencies(
      scriptRepository: ScriptRepositoryImpl(ScriptLocalDataSourceImpl(store)),
      teleprompterSettingsRepository: TeleprompterSettingsRepositoryImpl(
        TeleprompterSettingsLocalDataSourceImpl(store),
      ),
      appSettingsRepository: AppSettingsRepositoryImpl(
        AppSettingsLocalDataSourceImpl(store),
      ),
      recordingService: ScreenRecordingService(),
    );
  }
}
