import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/sync/data/sync_conflict_resolver.dart';

void main() {
  late SyncConflictResolver resolver;

  setUp(() {
    resolver = SyncConflictResolver();
  });

  group('_extractTimestamp', () {
    test('returns null when updatedAt is missing', () {
      final data = <String, dynamic>{'title': 'Test'};
      expect(resolver.extractTimestamp(data), isNull);
    });

    test('parses DateTime value', () {
      final now = DateTime.now();
      final data = <String, dynamic>{'updatedAt': now};
      expect(resolver.extractTimestamp(data), now);
    });

    test('parses ISO 8601 string', () {
      final data = <String, dynamic>{'updatedAt': '2026-07-25T12:00:00.000'};
      final parsed = resolver.extractTimestamp(data);
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 7);
      expect(parsed.day, 25);
    });

    test('returns null for invalid string', () {
      final data = <String, dynamic>{'updatedAt': 'not-a-date'};
      expect(resolver.extractTimestamp(data), isNull);
    });
  });

  group('_mergeData', () {
    test('merges local into remote, local overwrites', () {
      final remote = <String, dynamic>{'title': 'Remote', 'count': 1};
      final local = <String, dynamic>{'title': 'Local', 'extra': 'new'};

      final merged = resolver.mergeData(remote, local);
      expect(merged['title'], 'Local');
      expect(merged['count'], 1);
      expect(merged['extra'], 'new');
    });
  });
}
