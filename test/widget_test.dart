import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/app.dart';
import 'package:teleprompter/core/di/app_dependencies.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';

void main() {
  const Key contentField = ValueKey<String>('editor-content-field');

  Future<AppDependencies> bootApp(
    WidgetTester tester, {
    List<String> seeds = const <String>[],
  }) async {
    final AppDependencies deps = await AppDependencies.withStore(InMemoryKeyValueStore());
    for (int i = 0; i < seeds.length; i++) {
      await deps.saveScript(title: 'Script ${i + 1}', content: seeds[i]);
    }
    await tester.pumpWidget(TeleprompterApp(dependencies: deps));
    await tester.pumpAndSettle();
    return deps;
  }

  testWidgets('empty library shows the empty state and creates a script',
      (WidgetTester tester) async {
    await bootApp(tester);

    expect(find.text('Your scripts will appear here.'), findsOneWidget);
    expect(find.text('New Script'), findsOneWidget);

    await tester.tap(find.text('Create your first script'));
    await tester.pumpAndSettle();

    // The editor opens on the freshly created script.
    expect(find.byKey(contentField), findsOneWidget);

    // Typing drives the live statistics.
    await tester.enterText(find.byKey(contentField), 'Hello there, world.');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('3'), findsWidgets); // words
    expect(find.text('words'), findsOneWidget);
  });

  testWidgets('a saved script appears on the home screen with its stats',
      (WidgetTester tester) async {
    await bootApp(tester, seeds: <String>['one two three four five']);

    expect(find.text('Script 1'), findsOneWidget);
    expect(find.text('5 words'), findsOneWidget);
    expect(find.textContaining('one two three four five'), findsOneWidget);
  });

  testWidgets('delete is confirmed, removes the card and can be undone',
      (WidgetTester tester) async {
    await bootApp(tester, seeds: <String>['some script text']);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete script?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Script 1'), findsNothing);
    expect(find.text('Your scripts will appear here.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Script 1'), findsOneWidget);
  });

  testWidgets('full flow: script → editor → prompter reads, pauses and exits',
      (WidgetTester tester) async {
    final String longScript =
        List<String>.filled(600, 'read this line aloud.').join(' ');
    await bootApp(tester, seeds: <String>[longScript]);

    // Home → editor.
    await tester.tap(find.text('Script 1'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);

    // Editor → prompter.
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final Finder scrollable = find.byType(Scrollable).first;
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Play: the text moves at the requested speed.
    final double before = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    final double after = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(after, greaterThan(before));

    // Pause: the position freezes and stays frozen.
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    final double paused = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.state<ScrollableState>(scrollable).position.pixels, paused);

    // Speed can be nudged while reading.
    expect(find.textContaining('Speed  0.90'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.textContaining('Speed  0.95'), findsOneWidget);

    // Manual navigation still works while the session is paused.
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pump();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(paused),
    );

    // Leave the prompter cleanly.
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });
}
