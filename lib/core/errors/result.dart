import 'failures.dart';

/// Explicit success/failure return type for use cases.
///
/// Blocs branch on this with pattern matching, which keeps error handling
/// visible in the type signature instead of hiding it in thrown exceptions.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;

  Failure? get failureOrNull => this is Err<T> ? (this as Err<T>).failure : null;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
