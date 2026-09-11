import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/app.dart';
import 'package:teleprompter/core/di/app_dependencies.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';

/// Scripts of several thousand words are the reason this app exists, so the
/// prompter has to stay responsive when one is loaded and scrolled.
void main() {
  const int frames = 45;
  const Duration frameStep = Duration(milliseconds: 16);

  Future<ScrollableState> runPrompter(
    WidgetTester tester, {
    required String content,
    required Size size,
  }) async {
    // Tear the previous app down first: the navigator keeps its route stack,
    // and re-pumping the same widget types would reuse that state.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies deps = await AppDependencies.withStore(InMemoryKeyValueStore());
    await deps.saveScript(title: 'Take', content: content);

    await tester.pumpWidget(TeleprompterApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    return tester.state<ScrollableState>(find.byType(Scrollable).first);
  }

  /// Cost of [count] scrolling frames, in milliseconds.
  Future<int> timeFrames(WidgetTester tester) async {
    final Stopwatch watch = Stopwatch()..start();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    for (int i = 0; i < frames; i++) {
      await tester.pump(frameStep);
    }
    watch.stop();
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    return watch.elapsedMilliseconds;
  }

  testWidgets('a long script costs no more per frame than a short one',
      (WidgetTester tester) async {
    const Size size = Size(412, 915);

    // ~5,000 words over 25 paragraphs — roughly a 35 minute read.
    final String longScript = List<String>.filled(
      25,
      List<String>.filled(200, 'word').join(' '),
    ).join('\n\n');
    expect(longScript.split(RegExp(r'\s+')).length, 5000);

    final ScrollableState longScrollable =
        await runPrompter(tester, content: longScript, size: size);
    expect(
      longScrollable.position.maxScrollExtent,
      greaterThan(10000),
      reason: 'A long script must produce a long scroll extent',
    );
    final int longFrameCost = await timeFrames(tester);
    expect(longScrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);

    // Same number of frames with a one-line script.
    await runPrompter(tester, content: 'Three words here', size: size);
    final int shortFrameCost = await timeFrames(tester);
    debugPrint('frame cost — long: ${longFrameCost}ms, short: ${shortFrameCost}ms');

    // Scrolling must not get measurably more expensive as the script grows:
    // the engine writes one scroll offset per frame and never rebuilds the
    // script. Generous multiplier so this flags algorithmic regressions rather
    // than a slow machine.
    expect(longFrameCost, lessThan(shortFrameCost * 3 + 400));
  });
}
