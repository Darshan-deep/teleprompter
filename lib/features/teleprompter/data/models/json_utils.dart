/// Defensive readers used by the models.
///
/// Persisted JSON is untrusted input: a partially written file, a value written
/// by an older build, or a hand-edited store must never crash the app. Every
/// getter below falls back to a sane default instead of throwing.
abstract final class JsonUtils {
  static String readString(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static double readDouble(Object? value, {required double fallback}) {
    if (value is num) {
      final double result = value.toDouble();
      return result.isFinite ? result : fallback;
    }
    if (value is String) {
      final double? parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return fallback;
  }

  static bool readBool(Object? value, {required bool fallback}) =>
      value is bool ? value : fallback;

  static int? readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Reads a `DateTime` stored as ISO-8601 (falls back to epoch millis).
  static DateTime readDateTime(Object? value, {required DateTime fallback}) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    final int? millis = readInt(value);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    }
    return fallback;
  }

  /// Picks the enum value whose [name] matches, otherwise [fallback].
  static T readEnum<T extends Enum>(
    Object? value,
    List<T> values, {
    required T fallback,
    String Function(T value)? idOf,
  }) {
    if (value is! String) return fallback;
    for (final T candidate in values) {
      final String id = idOf?.call(candidate) ?? candidate.name;
      if (id == value) return candidate;
    }
    return fallback;
  }

  static Map<String, Object?> readMap(Object? value) {
    if (value is Map) {
      return value.map<String, Object?>(
        (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
      );
    }
    return const <String, Object?>{};
  }

  static List<Object?> readList(Object? value) => value is List ? value : const <Object?>[];
}
