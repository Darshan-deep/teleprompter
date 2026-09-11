import '../errors/exceptions.dart';

/// A user-presentable error. Blocs only ever expose [Failure]s, never raw
/// exceptions, so no data-layer type leaks into the widget tree.
class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  /// Maps any thrown object onto a friendly message.
  factory Failure.from(Object error) {
    if (error is AppException) return Failure(error.message, cause: error.cause ?? error);
    return const Failure('Something went wrong. Please try again.');
  }

  static const Failure scriptNotFound =
      Failure('This script is no longer available. It may have been deleted.');

  static const Failure storageUnavailable =
      Failure("Couldn't save to this device. Check available storage and try again.");

  @override
  String toString() => 'Failure($message)';
}
