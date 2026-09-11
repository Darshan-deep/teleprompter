import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/script.dart';
import '../../domain/repositories/script_repository.dart';
import '../datasources/script_local_data_source.dart';

/// Repository over the local script store.
///
/// Its only job is to translate storage exceptions into domain-facing
/// [AppException]s; the use cases above it decide what to do about them.
class ScriptRepositoryImpl implements ScriptRepository {
  const ScriptRepositoryImpl(this._localDataSource);

  final ScriptLocalDataSource _localDataSource;

  @override
  Future<List<Script>> getScripts() async {
    try {
      return await _localDataSource.readAll();
    } catch (error) {
      throw StorageException('Could not read your scripts', cause: error);
    }
  }

  @override
  Future<Script?> getScriptById(String id) async {
    if (id.isEmpty) return null;
    try {
      return await _localDataSource.readById(id);
    } catch (error) {
      throw StorageException('Could not read this script', cause: error);
    }
  }

  @override
  Future<Script> saveScript(Script script) async {
    if (!script.hasId) {
      throw const StorageException('Refusing to save a script without an id');
    }
    try {
      return await _localDataSource.upsert(script);
    } catch (error) {
      throw StorageException('Could not save this script', cause: error);
    }
  }

  @override
  Future<void> deleteScript(String id) async {
    if (id.isEmpty) return;
    try {
      await _localDataSource.deleteById(id);
    } catch (error) {
      throw StorageException('Could not delete this script', cause: error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _localDataSource.clear();
    } catch (error) {
      throw StorageException('Could not clear your scripts', cause: error);
    }
  }
}
