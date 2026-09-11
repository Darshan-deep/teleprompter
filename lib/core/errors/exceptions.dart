/// Low-level exceptions thrown by data sources and repositories.
///
/// They are always translated into a user-facing [Failure] before they reach a
/// widget, so the UI never has to interpret exception types itself.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

/// Local persistence failed (disk full, permission, plugin unavailable…).
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// The requested script does not exist (deleted on another screen, bad deep
/// link, corrupted store…).
class ScriptNotFoundException extends AppException {
  ScriptNotFoundException([String id = ''])
      : super(id.isEmpty ? 'Script not found' : 'Script "$id" not found');
}
