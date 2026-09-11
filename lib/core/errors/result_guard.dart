import 'failures.dart';
import 'result.dart';

/// Runs [action] and converts any thrown error into `Err(Failure)`.
///
/// Keeping this in one place means every use case has identical error semantics
/// and no exception can escape into the widget layer.
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Ok<T>(await action());
  } catch (error) {
    return Err<T>(Failure.from(error));
  }
}

/// Synchronous variant for pure computations that may still fail (bad input).
Result<T> guardSync<T>(T Function() action) {
  try {
    return Ok<T>(action());
  } catch (error) {
    return Err<T>(Failure.from(error));
  }
}
