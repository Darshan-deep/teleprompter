import 'package:shared_preferences/shared_preferences.dart';

/// Minimal persistence surface the data sources depend on.
///
/// Only `shared_preferences` is used (no extra packages), and going through
/// this interface keeps the data sources testable with an in-memory fake.
abstract interface class KeyValueStore {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

/// `shared_preferences`-backed store.
///
/// The plugin caches values in memory after the first load, so [read] is served
/// synchronously — which is what lets the data sources answer instantly while
/// the UI keeps a single await on the very first frame.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore._(this._preferences);

  final SharedPreferences _preferences;

  /// Loads the preference file. The only awaited storage call in the app.
  static Future<SharedPreferencesStore> open() async {
    return SharedPreferencesStore._(await SharedPreferences.getInstance());
  }

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}

/// In-memory store used by tests and as a safety net if the platform plugin is
/// unavailable — the app stays fully usable, it just forgets on restart.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? seed])
      : _values = <String, String>{...?seed};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
