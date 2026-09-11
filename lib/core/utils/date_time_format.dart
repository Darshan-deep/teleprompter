/// Human-friendly date formatting kept dependency-free and locale-neutral
/// enough for a single-language app.
abstract final class DateTimeFormat {
  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// `Just now`, `12m ago`, `3h ago`, `2d ago`, `Mar 4`, `Mar 4, 2024`.
  static String relative(DateTime value, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final DateTime local = value.toLocal();
    final Duration delta = reference.difference(local);

    if (delta.isNegative || delta.inSeconds < 45) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    if (local.year == reference.year) return '${_months[local.month - 1]} ${local.day}';
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  /// `Mar 4, 2026 · 14:05`
  static String full(DateTime value) {
    final DateTime local = value.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute';
  }
}
