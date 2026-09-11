import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/core/constants/storage_keys.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/key_value_store.dart';
import 'package:teleprompter/features/teleprompter/data/datasources/script_local_data_source.dart';
import 'package:teleprompter/features/teleprompter/data/repositories/script_repository_impl.dart';
import 'package:teleprompter/features/teleprompter/domain/entities/script.dart';
import 'package:teleprompter/features/teleprompter/domain/usecases/script_usecases.dart';

void main() {
  late InMemoryKeyValueStore store;
  late ScriptRepositoryImpl repository;
  late SaveScript saveScript;
  late GetScripts getScripts;
  late DuplicateScript duplicateScript;
  late DeleteScript deleteScript;

  setUp(() {
    store = InMemoryKeyValueStore();
    repository = ScriptRepositoryImpl(ScriptLocalDataSourceImpl(store));
    saveScript = SaveScript(repository);
    getScripts = GetScripts(repository);
    duplicateScript = DuplicateScript(repository);
    deleteScript = DeleteScript(repository);
  });

  test('saves, lists and reloads a script', () async {
    final result = await saveScript(title: 'Episode 3', content: 'Hello there.');
    final Script saved = result.valueOrNull!;

    expect(saved.id, isNotEmpty);
    expect(saved.title, 'Episode 3');

    final List<Script> all = (await getScripts()).valueOrNull!;
    expect(all, hasLength(1));
    expect(all.single.content, 'Hello there.');
  });

  test('normalises titles and stamps updatedAt while keeping createdAt', () async {
    final Script first =
        (await saveScript(title: '   messy    title  ', content: 'a')).valueOrNull!;
    expect(first.title, 'messy title');

    final Script second = (await saveScript(
      id: first.id,
      title: 'renamed',
      content: 'b',
      now: first.createdAt.add(const Duration(hours: 2)),
    ))
        .valueOrNull!;

    expect(second.title, 'renamed');
    expect(second.createdAt, first.createdAt);
    expect(second.updatedAt.isAfter(first.updatedAt), isTrue);
  });

  test('blank titles fall back to the untitled default', () async {
    final Script script = (await saveScript(title: '   ', content: 'x')).valueOrNull!;
    expect(script.displayTitle, 'Untitled script');
  });

  test('deleting is idempotent', () async {
    final Script script = (await saveScript(title: 'a', content: 'b')).valueOrNull!;
    expect((await deleteScript(script.id)).isOk, isTrue);
    expect((await deleteScript(script.id)).isOk, isTrue);
    expect((await getScripts()).valueOrNull, isEmpty);
  });

  test('duplicates keep the text and gain a " copy" title', () async {
    final Script original = (await saveScript(title: 'Take 1', content: 'body')).valueOrNull!;
    final Script copy = (await duplicateScript(original.id)).valueOrNull!;

    expect(copy.id, isNot(original.id));
    expect(copy.title, 'Take 1 copy');
    expect(copy.content, original.content);
    expect((await getScripts()).valueOrNull, hasLength(2));
  });

  test('missing scripts resolve to null instead of throwing', () async {
    expect((await GetScript(repository)('nope')).valueOrNull, isNull);
    final missing = await duplicateScript('nope');
    expect(missing.isOk, isFalse);
  });

  test('corrupt storage degrades to an empty list', () async {
    await store.write(StorageKeys.scripts, '{not json at all');
    expect((await getScripts()).valueOrNull, isEmpty);

    // ...and the store is usable again straight away.
    final Script script = (await saveScript(title: 'after', content: 'ok')).valueOrNull!;
    expect((await getScripts()).valueOrNull!.single.id, script.id);
  });

  test('records without an id are skipped rather than breaking the read', () async {
    await store.write(
      StorageKeys.scripts,
      '[{"title":"no id","content":"x"},{"id":"keep","title":"keep","content":"y"}]',
    );
    final List<Script> scripts = (await getScripts()).valueOrNull!;
    expect(scripts, hasLength(1));
    expect(scripts.single.id, 'keep');
  });

  test('scripts are returned most recently edited first', () async {
    final DateTime base = DateTime(2026, 1, 1);
    await saveScript(title: 'old', content: 'a', now: base);
    await saveScript(title: 'new', content: 'b', now: base.add(const Duration(days: 1)));
    final List<Script> scripts = (await getScripts()).valueOrNull!;
    expect(scripts.first.title, 'new');
  });
}
