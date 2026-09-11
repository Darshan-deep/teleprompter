import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/app.dart';
import 'package:teleprompter/core/di/app_dependencies.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';
import 'package:teleprompter/features/teleprompter/presentation/widgets/prompt_text_view.dart';
import 'package:teleprompter/features/teleprompter/presentation/widgets/prompter_controls.dart';
import 'package:teleprompter/features/teleprompter/presentation/widgets/reading_guide.dart';

void main() {
  /// Regression guard for the whole reading surface: the guide and the progress
  /// bar are laid out over the text, and a mis-sized box would silently paint
  /// nothing at all.
  testWidgets('prompter paints its reading guide and progress line',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies deps = await AppDependencies.withStore(InMemoryKeyValueStore());
    final String script = await _seed(deps);

    await tester.pumpWidget(TeleprompterApp(dependencies: deps));
    await tester.pumpAndSettle();

    // Straight into the prompter through the deep link the router exposes.
    await tester.tap(find.text(script));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    final Finder guide = find.descendant(
      of: find.byType(ReadingGuide),
      matching: find.byType(CustomPaint),
    );
    expect(guide, findsOneWidget);
    expect(tester.getSize(guide).width, greaterThan(320));
    expect(
      tester.getCenter(guide).dy / 800,
      closeTo(PrompterLayout.readingLineFraction, 0.02),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).width, greaterThan(320));

    // The script itself is on the canvas and starts at the reading line.
    final Finder paragraphs = find.descendant(
      of: find.byType(PromptTextView),
      matching: find.byType(Text),
    );
    expect(paragraphs, findsWidgets);
    expect(tester.getTopLeft(paragraphs.first).dy, lessThan(800 * PrompterLayout.readingLineFraction));
  });

  testWidgets('tapping hides the controls and a second tap brings them back',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies deps = await AppDependencies.withStore(InMemoryKeyValueStore());
    await _seed(deps);
    await tester.pumpWidget(TeleprompterApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    // The panel fades and slides out rather than leaving the tree, so the
    // assertion is on its opacity.
    double panelOpacity() => tester
        .widgetList<AnimatedOpacity>(
          find.ancestor(
            of: find.byType(PrompterControls),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .first
        .opacity;

    expect(panelOpacity(), 1);

    // A tap over the script hides everything the reader does not need. The
    // hide lands once the double-tap window has passed.
    await tester.tapAt(const Offset(200, 260));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(panelOpacity(), 0);

    // Touching the screen brings the controls back immediately — no waiting for
    // a possible second tap.
    await tester.tapAt(const Offset(200, 260));
    await tester.pump(const Duration(milliseconds: 16));
    expect(panelOpacity(), 1);

    // ...and the double tap toggles playback without leaving the controls
    // stuck on screen afterwards.
    await tester.tapAt(const Offset(200, 260));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tapAt(const Offset(200, 260));
    // Deliberately not `pumpAndSettle`: the prompter is animating by design, so
    // settling would run the entire script to its end.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // A double tap also pauses again.
    await tester.tapAt(const Offset(200, 260));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tapAt(const Offset(200, 260));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
  });
}

Future<String> _seed(AppDependencies deps) async {
  final String content = List<String>.filled(120, 'a line to read from the prompter.')
      .join(' ');
  await deps.saveScript(title: 'Take one', content: content);
  return 'Take one';
}
