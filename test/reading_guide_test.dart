import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/features/teleprompter/presentation/widgets/prompt_text_view.dart';
import 'package:teleprompter/features/teleprompter/presentation/widgets/reading_guide.dart';

void main() {
  const Size phone = Size(390, 800);

  /// The guide is positioned relative to the canvas it is given, so every case
  /// below runs at a real device size rather than the default test surface.
  Future<void> pumpGuide(
    WidgetTester tester, {
    required bool visible,
    Size size = phone,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(width: size.width, height: size.height, child: Stack(
            children: <Widget>[
              Positioned.fill(child: ReadingGuide(color: Colors.white, visible: visible)),
            ],
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the guide spans the screen at the reading line', (WidgetTester tester) async {
    await pumpGuide(tester, visible: true);

    final Finder painter = find.descendant(
      of: find.byType(ReadingGuide),
      matching: find.byType(CustomPaint),
    );
    final Size size = tester.getSize(painter);

    expect(size.height, greaterThan(0));
    expect(
      size.width,
      greaterThan(phone.width * 0.8),
      reason: 'The guide must actually be laid out — a collapsed box paints nothing',
    );

    // Sits on the reading line, slightly above the vertical centre.
    final Offset center = tester.getCenter(painter);
    expect(
      center.dy / phone.height,
      closeTo(PrompterLayout.readingLineFraction, 0.02),
    );
    expect(center.dx, closeTo(phone.width / 2, 1));
  });

  testWidgets('the guide adapts to any canvas size', (WidgetTester tester) async {
    const Size landscape = Size(844, 390);
    await pumpGuide(tester, visible: true, size: landscape);

    final Finder painter = find.descendant(
      of: find.byType(ReadingGuide),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(painter).width, greaterThan(landscape.width * 0.8));
    expect(
      tester.getCenter(painter).dy / landscape.height,
      closeTo(PrompterLayout.readingLineFraction, 0.02),
    );
  });

  testWidgets('a hidden guide takes no visual space', (WidgetTester tester) async {
    await pumpGuide(tester, visible: false);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
  });
}
