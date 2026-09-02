import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  LongTermMemory memory({
    required String id,
    String content = 'content',
    double importance = 0.5,
    String type = 'fact',
  }) {
    return LongTermMemory(
      id: id,
      type: MemoryEntryType.values.firstWhere((e) => e.name == type),
      content: content,
      importance: importance,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  group('InMemoryMemoryStore', () {
    test('add, get and delete round-trip', () async {
      final store = InMemoryMemoryStore();
      await store.add(memory(id: 'm1', content: 'budget is 200k'));

      final loaded = await store.get('m1');
      expect(loaded, isNotNull);
      expect(loaded!.content, 'budget is 200k');
      expect((await store.all()).length, 1);

      await store.delete('m1');
      expect(await store.get('m1'), isNull);
    });

    test('search matches content and ranks by term overlap', () async {
      final store = InMemoryMemoryStore();
      await store.addAll([
        memory(id: 'm1', content: 'school budget is capped at 200k'),
        memory(id: 'm2', content: 'supplier invoice due in 14 days'),
        memory(id: 'm3', content: 'budget approval needed by Friday'),
      ]);

      final results = await store.search('budget');
      expect(results.map((m) => m.id).toSet(), {'m1', 'm3'});
      expect(results.first.content, contains('budget'));
    });

    test('search is case-insensitive and partial', () async {
      final store = InMemoryMemoryStore();
      await store.add(memory(id: 'm1', content: 'Budget Review'));
      expect(await store.search('BUDGET'), hasLength(1));
      expect(await store.search('bud'), hasLength(1));
    });

    test('touch bumps access count and recency', () async {
      final store = InMemoryMemoryStore();
      await store.add(memory(id: 'm1'));
      await store.touch('m1');
      final touched = await store.get('m1');
      expect(touched!.accessCount, 1);
      expect(touched.lastAccessedAt, isNotNull);
    });

    test('important sorts by importance descending', () async {
      final store = InMemoryMemoryStore();
      await store.addAll([
        memory(id: 'low', importance: 0.2),
        memory(id: 'high', importance: 0.9),
      ]);
      final results = await store.important();
      expect(results.first.id, 'high');
    });
  });

  group('PersistentMemoryStore (offline-first)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists across store instances', () async {
      final store = PersistentMemoryStore();
      await store.add(memory(id: 'm1', content: 'remember me'));

      final reloaded = PersistentMemoryStore();
      final all = await reloaded.all();
      expect(all, hasLength(1));
      expect(all.first.content, 'remember me');
    });

    test('search works on reloaded data', () async {
      final store = PersistentMemoryStore();
      await store.add(memory(id: 'm1', content: 'call Alhaji before noon'));
      await store.add(memory(id: 'm2', content: 'buy flour on Friday'));

      final reloaded = PersistentMemoryStore();
      final hits = await reloaded.search('flour');
      expect(hits.map((m) => m.id), ['m2']);
    });

    test('delete is persisted', () async {
      final store = PersistentMemoryStore();
      await store.add(memory(id: 'm1'));
      await store.delete('m1');

      final reloaded = PersistentMemoryStore();
      expect(await reloaded.all(), isEmpty);
    });
  });
}
