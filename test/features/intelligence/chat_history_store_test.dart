import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('append stores messages per conversation', () async {
    final store = InMemoryChatHistoryStore();
    await store.append('c1', const IntelligenceMessage(role: IntelligenceRole.user, content: 'hi'));
    await store.append('c1', const IntelligenceMessage(role: IntelligenceRole.assistant, content: 'hello'));
    await store.append('c2', const IntelligenceMessage(role: IntelligenceRole.user, content: 'other'));

    expect(await store.conversationIds(), hasLength(2));
    final c1 = await store.messages('c1');
    expect(c1, hasLength(2));
    expect(c1.first.role, IntelligenceRole.user);
  });

  test('limit keeps the newest messages', () async {
    final store = InMemoryChatHistoryStore();
    for (var i = 0; i < 5; i++) {
      await store.append('c1', IntelligenceMessage(role: IntelligenceRole.user, content: 'm$i'));
    }
    final recent = await store.messages('c1', limit: 2);
    expect(recent, hasLength(2));
    expect(recent.last.content, 'm4');
  });

  test('clear removes a conversation', () async {
    final store = InMemoryChatHistoryStore();
    await store.append('c1', const IntelligenceMessage(role: IntelligenceRole.user, content: 'hi'));
    await store.clear('c1');
    expect(await store.messages('c1'), isEmpty);
    expect(await store.conversationIds(), isEmpty);
  });
}
