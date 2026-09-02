# Scalability Architecture

## 1. Firestore Read/Write Cost Estimates

### Per-User Daily Usage (Conservative)
| Operation | Daily Count | Read Cost | Write Cost |
|-----------|-------------|-----------|------------|
| App open (load conversations) | 5 | 5 reads | 0 |
| Send message | 10 | 0 | 10 writes |
| Receive AI response | 10 | 0 | 10 writes |
| View saved items | 2 | 2 reads | 0 |
| Load settings | 1 | 1 read | 0 |
| Update settings | 1 | 0 | 1 write |
| **Total per user/day** | | **8 reads** | **21 writes** |

### Monthly Cost Projections
| Scale | Users | Reads/mo | Writes/mo | Firestore Cost | AI API Cost (est.) | Total |
|-------|-------|----------|-----------|----------------|-------------------|-------|
| MVP | 1,000 | 240K | 630K | Free tier | ~$50-100 | ~$50-100 |
| Growth | 10,000 | 2.4M | 6.3M | ~$40 | ~$500-1,000 | ~$540-1,040 |
| Scale | 100,000 | 24M | 63M | ~$400 | ~$5,000-10,000 | ~$5,400-10,400 |
| Enterprise | 1,000,000 | 240M | 630M | ~$4,000 | ~$50,000-100,000 | ~$54,000-104,000 |

**Key insight**: AI API costs dominate at scale, not Firestore. Optimizing prompt tokens and model selection has more financial impact than optimizing database reads.

## 2. Chat Document Size Strategy

### Problem
Firestore has a 1MB limit per document. A long conversation with 500+ messages could exceed this.

### Strategy: Hybrid Document-Subcollection Model

**For active conversations (last 90 days):**
```
conversations/{convId}  (stores last 50 messages inline)
  +-- messages/{msgId}  (subcollection for full history)
```

**Rules:**
- The conversation document stores the *latest 50 messages* inline for fast loading
- Older messages live in the `messages` subcollection
- When loading a conversation: load doc (instant) + lazy-load subcollection for "load more"
- On each new message: push to subcollection + trim inline to keep only last 50

**Message subcollection document size:**
```json
{
  "id": "msg_001",
  "role": "user",
  "content": "string (up to ~10KB)",
  "timestamp": "2026-07-27T12:00:00Z",
  "tokensUsed": 150
}
```

Each message ~200 bytes average. 1MB limit = ~5,000 messages per conversation. Realistically, conversations rarely exceed 1,000 messages.

**For conversations older than 90 days:**
- Archive to Cloud Storage as JSON
- Delete from Firestore (with archive reference in conversation doc)
- On user request: restore from archive

## 3. Conversation Pagination

```dart
// Firestore query
Future<List<ConversationSummary>> getConversations({
  required String userId,
  String? startAfter, // cursor-based pagination
  int limit = 20,
}) async {
  var query = FirebaseFirestore.instance
      .collection('conversations')
      .where('userId', isEqualTo: userId)
      .where('deletedAt', isNull: true)
      .orderBy('lastMessageAt', descending: true)
      .limit(limit);

  if (startAfter != null) {
    final cursor = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(startAfter)
        .get();
    query = query.startAfterDocument(cursor);
  }

  final snapshot = await query.get();
  return snapshot.docs.map((doc) => ConversationSummary.fromFirestore(doc)).toList();
}
```

**Key decisions:**
- Cursor-based pagination (not offset-based) for Firestore efficiency
- Conversations list loads `ConversationSummary` only (no messages)
- Full conversation (with last 50 messages) fetched on open
- Older messages lazy-loaded via subcollection query

## 4. Indexing Strategy

### Composite Indexes Required

| Collection | Fields | Purpose |
|------------|--------|---------|
| conversations | userId, deletedAt, lastMessageAt DESC | Conversation list |
| conversations | userId, isStarred, updatedAt DESC | Starred conversations |
| messages | conversationId, timestamp ASC | Message history |
| memories | userId, type, updatedAt DESC | Memory list by type |
| saved_items | userId, type, createdAt DESC | Saved items list |
| usage_stats | userId, date | Daily usage per user |

### Firestore Index Configuration (indexes.json)
```json
{
  "indexes": [
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "deletedAt", "order": "ASCENDING" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "conversationId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## 5. Scaling Beyond 1M Users

At very large scale, consider:

1. **Read replication**: Use Firebase Replicator or custom replica for analytics-heavy queries
2. **Conversation archival**: Automatically archive conversations >6 months old to Cloud Storage
3. **Shard by region**: Multi-region Firestore if latency becomes an issue in specific African markets
4. **Cache layer**: Redis/Memorystore for frequently accessed data (user profiles, settings)
5. **Read-only Firestore replicas**: Separate read traffic from write traffic

**Recommendation**: Don't optimize for 1M users until you have 100K. The architecture above scales to 100K without changes.
