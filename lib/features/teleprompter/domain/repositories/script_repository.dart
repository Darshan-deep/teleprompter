import '../entities/script.dart';

/// Contract for script persistence. Implementations live in the data layer and
/// may throw [AppException]s, which use cases translate into `Result`s.
abstract interface class ScriptRepository {
  /// All scripts, most recently edited first.
  Future<List<Script>> getScripts();

  /// A single script, or `null` when the id is unknown (deleted, bad link…).
  Future<Script?> getScriptById(String id);

  /// Inserts or replaces a script and returns the persisted entity.
  Future<Script> saveScript(Script script);

  /// Removes a script. Deleting an unknown id is a no-op so the UI can treat
  /// deletion as idempotent.
  Future<void> deleteScript(String id);

  /// Removes every script (used by "Reset settings" → wipe data flows).
  Future<void> deleteAll();
}
