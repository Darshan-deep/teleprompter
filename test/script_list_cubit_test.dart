import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/script_local_data_source.dart';
import 'package:teleprompter/features/teleprompter/data/repositories/script_repository_impl.dart';
import 'package:teleprompter/features/teleprompter/domain/entities/script.dart';
import 'package:teleprompter/features/teleprompter/domain/usecases/script_usecases.dart';
import 'package:teleprompter/features/teleprompter/presentation/bloc/script_list_cubit.dart';
import 'package:teleprompter/features/teleprompter/presentation/bloc/script_list_state.dart';

void main() {
  late ScriptRepositoryImpl repository;
  late ScriptListCubit cubit;

  setUp(() {
    repository = ScriptRepositoryImpl(
      ScriptLocalDataSourceImpl(InMemoryKeyValueStore()),
    );
    cubit = ScriptListCubit(
      getScripts: GetScripts(repository),
      saveScript: SaveScript(repository),
      deleteScript: DeleteScript(repository),
      duplicateScript: DuplicateScript(repository),
    );
  });

  tearDown(() => cubit.close());

  test('starts empty and becomes ready', () async {
    expect(cubit.state.status, ScriptListStatus.initial);
    await cubit.load();
    expect(cubit.state.status, ScriptListStatus.ready);
    expect(cubit.state.isEmpty, isTrue);
  });

  test('creating a script puts it at the top of the list', () async {
    await cubit.load();
    final Script? created = await cubit.createScript(title: 'Intro', content: 'hi');
    expect(created, isNotNull);
    expect(cubit.state.scripts.single.title, 'Intro');
    expect(cubit.state.isEmpty, isFalse);
  });

  test('rename and duplicate update the list', () async {
    await cubit.load();
    final Script created = (await cubit.createScript(title: 'A', content: 'x'))!;

    expect(await cubit.renameScript(created.id, 'B'), isTrue);
    expect(cubit.state.scripts.single.title, 'B');

    final Script? copy = await cubit.duplicateScript(created.id);
    expect(copy, isNotNull);
    expect(cubit.state.scripts, hasLength(2));
    expect(cubit.state.scripts.map((Script s) => s.title), contains('B copy'));
  });

  test('delete removes the script and undo brings it back', () async {
    await cubit.load();
    final Script created = (await cubit.createScript(title: 'Take', content: 'x'))!;

    expect(await cubit.deleteScript(created.id), isTrue);
    expect(cubit.state.scripts, isEmpty);

    final Script? restored = await cubit.restoreScript(created);
    expect(restored, isNotNull);
    expect(cubit.state.scripts.single.id, created.id);

    // The undo really persisted: a fresh read sees it too.
    expect((await GetScripts(repository)()).valueOrNull, hasLength(1));
  });

  test('renaming a script that no longer exists is a no-op', () async {
    await cubit.load();
    expect(await cubit.renameScript('missing', 'x'), isFalse);
  });
}
