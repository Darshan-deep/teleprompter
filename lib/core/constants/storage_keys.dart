/// Keys used with [KeyValueStore]. Versioned so a future migration can read the
/// previous payload shape.
abstract final class StorageKeys {
  static const String scripts = 'teleprompter.scripts.v1';
  static const String teleprompterSettings = 'teleprompter.settings.v1';
  static const String appSettings = 'teleprompter.app_settings.v1';
}
