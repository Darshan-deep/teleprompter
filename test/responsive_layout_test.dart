import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/app.dart';
import 'package:teleprompter/core/di/app_dependencies.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';

/// Every screen is exercised at real device sizes. A RenderFlex overflow throws
/// in tests, so this file is the guard rail against layouts that only look
/// right on a big window.
void main() {
  const Map<String, Size> canvases = <String, Size>{
    'small phone': Size(320, 568),
    'phone landscape': Size(844, 390),
    'tablet': Size(1024, 768),
  };

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies deps = await AppDependencies.withStore(InMemoryKeyValueStore());
    await deps.saveScript(title: 'Take one', content: 'line to read. ' * 60);
    await tester.pumpWidget(TeleprompterApp(dependencies: deps));
    await tester.pumpAndSettle();
  }

  for (final MapEntry<String, Size> canvas in canvases.entries) {
    testWidgets('home, editor and setup sheet lay out on ${canvas.key}',
        (WidgetTester tester) async {
      await pumpHome(tester, canvas.value);
      expect(find.text('New Script'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Take one'));
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The reading-setup sheet carries the widest set of controls in the app.
      await tester.tap(
        find.byTooltip(canvas.value.width < 430 ? 'Reading setup' : 'More settings'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reading setup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('prompter lays out and scrolls on ${canvas.key}',
        (WidgetTester tester) async {
      await pumpHome(tester, canvas.value);
      await tester.tap(find.text('Take one'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Run it for a couple of seconds: the moving layout must stay valid.
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      for (int i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
