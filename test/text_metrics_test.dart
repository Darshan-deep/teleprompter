import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/core/utils/text_metrics.dart';

void main() {
  group('TextMetrics.wordCount', () {
    test('counts words across paragraphs', () {
      expect(TextMetrics.wordCount(''), 0);
      expect(TextMetrics.wordCount('   \n  '), 0);
      expect(TextMetrics.wordCount('one'), 1);
      expect(TextMetrics.wordCount('one two\nthree'), 3);
      expect(TextMetrics.wordCount('Hello   world.\n\nSecond paragraph.'), 4);
    });

    test('is stable for a very long script', () {
      final String script = List<String>.filled(5000, 'word').join(' ');
      expect(TextMetrics.wordCount(script), 5000);
    });
  });

  group('TextMetrics.paragraphCount', () {
    test('splits on blank lines only', () {
      expect(TextMetrics.paragraphCount('a\nb'), 1);
      expect(TextMetrics.paragraphCount('a\n\nb'), 2);
      expect(TextMetrics.paragraphCount('a\n \n b\n\n\nc'), 3);
      expect(TextMetrics.paragraphCount('   '), 0);
    });
  });

  group('TextMetrics.preview', () {
    test('collapses whitespace and trims on a word boundary', () {
      expect(TextMetrics.preview('  hello   world  '), 'hello world');
      final String preview = TextMetrics.preview('word ' * 60, maxLength: 40);
      expect(preview.length, lessThanOrEqualTo(41));
      expect(preview.endsWith('…'), isTrue);
      expect(preview.contains('  '), isFalse);
    });
  });

  group('read time', () {
    test('estimates from an average reading pace', () {
      expect(TextMetrics.estimatedReadTime(''), Duration.zero);
      expect(TextMetrics.estimatedReadTime('word ' * 150).inSeconds, 60);
    });

    test('formats human friendly labels', () {
      expect(TextMetrics.formatReadTime(const Duration(seconds: 5)), 'under 10s');
      expect(TextMetrics.formatReadTime(const Duration(seconds: 45)), '45s');
      expect(TextMetrics.formatReadTime(const Duration(seconds: 80)), '1m 20s');
      expect(TextMetrics.formatReadTime(const Duration(minutes: 2)), '2m');
    });
  });
}
