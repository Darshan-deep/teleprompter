import '../constants/app_constants.dart';

/// Pure text statistics used by the home cards, the editor and the prompter.
///
/// Everything here is O(n) over the script content and never touches the widget
/// tree, so it stays cheap even for scripts with thousands of words.
abstract final class TextMetrics {
  static final RegExp _wordPattern = RegExp(r'\S+');
  static final RegExp _blankLineSplit = RegExp(r'\n[ \t]*\n');
  static final RegExp _collapse = RegExp(r'\s+');

  static int wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return _wordPattern.allMatches(text).length;
  }

  /// All characters, including spaces and line breaks.
  static int characterCount(String text) => text.length;

  /// Paragraphs are separated by blank lines, matching how scripts are typed.
  static int paragraphCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text
        .trim()
        .split(_blankLineSplit)
        .where((String paragraph) => paragraph.trim().isNotEmpty)
        .length;
  }

  /// Estimated out-loud duration at an average reading pace.
  static Duration estimatedReadTime(String text) {
    final int words = wordCount(text);
    if (words == 0) return Duration.zero;
    return Duration(seconds: ((words / AppConstants.wordsPerMinute) * 60).round());
  }

  /// Single-line preview for cards: collapses whitespace and trims to a sane
  /// length without cutting mid-word.
  static String preview(String text, {int maxLength = AppConstants.cardPreviewLength}) {
    final String flat = text.trim().replaceAll(_collapse, ' ');
    if (flat.length <= maxLength) return flat;
    final String clipped = flat.substring(0, maxLength);
    final int lastSpace = clipped.lastIndexOf(' ');
    final String trimmed = lastSpace > maxLength * 0.6 ? clipped.substring(0, lastSpace) : clipped;
    return '${trimmed.trimRight()}…';
  }

  static bool isBlank(String text) => text.trim().isEmpty;

  /// `1m 20s` / `48s` / `under 10s` for read-time estimates.
  static String formatReadTime(Duration duration) {
    if (duration.inSeconds == 0) return '0s';
    if (duration.inSeconds < 10) return 'under 10s';
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return seconds == 0 ? '${minutes}m' : '${minutes}m ${seconds}s';
  }
}
