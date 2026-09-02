# TDR-005: Sync Strategy

**Date**: 2026-07-27
**Version**: 1.0.0

## Decision
**Offline-first** with a local-first write pattern and background sync queue.

## Alternatives Considered
1. **Online-only** — Simpler to implement, no conflict resolution needed. Useless without internet, poor UX in Nigeria/Africa where connectivity is unreliable.
2. **Firestore offline persistence** — Built into Firestore SDK, zero effort. Limited control, no custom conflict resolution, no queue visibility, doesn't sync to a local relational DB.
3. **Offline-first with custom sync engine** — Maximum control, offline-capable, user sees their data instantly. More implementation effort, must handle conflict resolution.

## Reasoning
- Banataq must work in areas with unreliable internet (core principle)
- Users should never see a loading spinner when reading their conversations
- Optimistic writes make the app feel instant
- Custom sync queue gives visibility into pending operations for debugging
- Conflict resolution by "latest timestamp wins" is simple and predictable
- Isar + Firestore sync is a proven pattern at scale

## Trade-offs
- **Gain**: Instant UI, works offline, full sync visibility, user trust
- **Sacrifice**: Complex sync engine, conflict resolution edge cases, extra storage for sync queue
