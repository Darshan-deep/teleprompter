import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/result_guard.dart';
import '../../../../core/utils/id_generator.dart';
import '../entities/script.dart';
import '../repositories/script_repository.dart';

/// Loads every stored script, newest edit first.
class GetScripts {
  const GetScripts(this._repository);

  final ScriptRepository _repository;

  Future<Result<List<Script>>> call() =>
      guard<List<Script>>(_repository.getScripts);
}

/// Loads one script. Unknown ids resolve to `Ok(null)` rather than an error so
/// navigation can show a friendly "no longer available" state.
class GetScript {
  const GetScript(this._repository);

  final ScriptRepository _repository;

  Future<Result<Script?>> call(String id) =>
      guard<Script?>(() => _repository.getScriptById(id));
}

/// Creates or updates a script.
///
/// Normalisation lives here so no widget or cubit has to remember to trim
/// titles, stamp `updatedAt` or preserve `createdAt`:
///
/// * blank titles become "Untitled script" (duplicates are allowed on purpose —
///   a user recording ten takes should not be blocked);
/// * titles are trimmed and capped at [AppConstants.maxTitleLength];
/// * `createdAt` is preserved on update (or supplied when restoring a deleted
///   script), `updatedAt` is always refreshed;
/// * a missing id means "create".
class SaveScript {
  const SaveScript(this._repository);

  final ScriptRepository _repository;

  Future<Result<Script>> call({
    String? id,
    required String title,
    required String content,
    DateTime? now,
    DateTime? createdAt,
  }) {
    return guard<Script>(() async {
      final DateTime timestamp = now ?? DateTime.now();
      final String normalizedTitle = _normalizeTitle(title);

      Script? existing;
      if (id != null && id.isNotEmpty) {
        existing = await _repository.getScriptById(id);
      }

      final Script script = Script(
        id: existing?.id ?? (id?.isNotEmpty ?? false ? id! : IdGenerator.newId()),
        title: normalizedTitle,
        content: content,
        createdAt: existing?.createdAt ?? createdAt ?? timestamp,
        updatedAt: timestamp,
      );

      return _repository.saveScript(script);
    });
  }

  static String _normalizeTitle(String raw) {
    final String trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return AppConstants.untitledScriptTitle;
    if (trimmed.length <= AppConstants.maxTitleLength) return trimmed;
    return trimmed.substring(0, AppConstants.maxTitleLength).trimRight();
  }
}

/// Deletes a script. Idempotent: deleting an already-deleted script succeeds.
class DeleteScript {
  const DeleteScript(this._repository);

  final ScriptRepository _repository;

  Future<Result<void>> call(String id) =>
      guard<void>(() => _repository.deleteScript(id));
}

/// Copies a script, including its text, under a " copy" title.
class DuplicateScript {
  const DuplicateScript(this._repository);

  final ScriptRepository _repository;

  Future<Result<Script>> call(String id, {DateTime? now}) {
    return guard<Script>(() async {
      final Script? source = await _repository.getScriptById(id);
      if (source == null) {
        throw const ScriptMissingException();
      }
      return _repository.saveScript(
        source.duplicate(newId: IdGenerator.newId(), now: now ?? DateTime.now()),
      );
    });
  }
}

/// Thrown when a script referenced by the UI has vanished underneath it.
class ScriptMissingException implements Exception {
  const ScriptMissingException();
}
