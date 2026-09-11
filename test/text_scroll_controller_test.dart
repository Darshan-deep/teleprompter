import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/features/teleprompter/presentation/engine/text_scroll_controller.dart';

void main() {
  Future<TextScrollController> pumpEngine(WidgetTester tester, {double extent = 4000}) async {
    final TextScrollController engine = TextScrollController(vsync: const TestVSync());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: engine.scrollController,
            child: SizedBox(height: extent, width: 200),
          ),
        ),
      ),
    );
    await tester.pump();
    return engine;
  }

  testWidgets('advances at the requested rate and reports completion', (WidgetTester tester) async {
    final TextScrollController engine = await pumpEngine(tester);
    final double maxExtent = engine.scrollController.position.maxScrollExtent;
    bool completed = false;
    engine
      ..onCompleted = () {
        completed = true;
      }
      ..setPixelsPerSecond(1000)
      ..play();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final double offset = engine.scrollController.offset;
    expect(offset, greaterThan(200));
    expect(offset, lessThanOrEqualTo(400)); // 1000 px/s for 0.3 s, with tolerance
    expect(engine.isPlaying, isTrue);

    // Run well past the end of the content.
    await tester.pump(Duration(milliseconds: (maxExtent).round() + 500));
    expect(completed, isTrue);
    expect(engine.isPlaying, isFalse);
    expect(engine.isAtEnd, isTrue);

    engine.dispose();
  });

  testWidgets('pausing freezes the position', (WidgetTester tester) async {
    final TextScrollController engine = await pumpEngine(tester);
    engine
      ..setPixelsPerSecond(800)
      ..play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    engine.pause();
    final double paused = engine.scrollController.offset;
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.scrollController.offset, paused);
    engine.dispose();
  });

  testWidgets('restart returns to the top', (WidgetTester tester) async {
    final TextScrollController engine = await pumpEngine(tester);
    engine
      ..setPixelsPerSecond(2000)
      ..play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(engine.scrollController.offset, greaterThan(0));

    engine.restart();
    await tester.pump();
    expect(engine.scrollController.offset, lessThan(50));
    engine.pause();
    engine.dispose();
  });

  testWidgets('content that fits on screen never reports completion',
      (WidgetTester tester) async {
    final TextScrollController engine = await pumpEngine(tester, extent: 100);
    bool completed = false;
    engine
      ..onCompleted = () {
        completed = true;
      }
      ..setPixelsPerSecond(500)
      ..play();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(engine.isScrollable, isFalse);
    expect(completed, isFalse);
    expect(engine.isPlaying, isTrue);
    engine.pause();
    engine.dispose();
  });

  testWidgets('very slow speeds stay smooth instead of stalling',
      (WidgetTester tester) async {
    final TextScrollController engine = await pumpEngine(tester);
    engine
      ..setPixelsPerSecond(3) // ~ the slowest the UI can ask for
      ..play();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(engine.scrollController.offset, greaterThan(0));
    engine.pause();
    engine.dispose();
  });
}
