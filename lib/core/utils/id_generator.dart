import 'dart:math';

/// Generates collision-resistant local ids.
///
/// Timestamp-first ids keep scripts in creation order when sorted by id, which
/// is handy for optimistic inserts before the store is re-read.
abstract final class IdGenerator {
  static final Random _random = Random.secure();
  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const int _suffixLength = 6;

  static String newId() {
    final String stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final StringBuffer buffer = StringBuffer(stamp)..write('-');
    for (int i = 0; i < _suffixLength; i++) {
      buffer.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}
