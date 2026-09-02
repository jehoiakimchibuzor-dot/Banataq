# TDR-001: Local Database

**Date**: 2026-07-27
**Version**: 1.0.0

## Decision
Use **Isar** as the local on-device database.

## Alternatives Considered
1. **Drift (SQLite)** — Mature, well-documented, raw SQL control. Heavier, more boilerplate, no built-in reactive streams.
2. **Hive** — Fast key-value store, but no relational queries, no indexing, no complex data modeling.
3. **SQLite (direct via sqflite)** — Maximum control, but manual migrations, no type safety, error-prone.
4. **Isar** — NoSQL document DB built for Flutter. Fast (mmap-based), reactive queries, built-in indexing, automatic migrations, type-safe with code generation. Smaller community than Drift, but purpose-built for Flutter.

## Reasoning
- Isar is 2-3x faster than SQLite on mobile (mmap-based storage)
- Built-in reactive streams (watch()) simplify the sync engine
- Automatic schema migration reduces maintenance
- Type-safe queries at compile time via code generation
- Works well with the offline-first sync pattern (local writes = fast, sync = background)

## Trade-offs
- **Gain**: Blazing fast local reads/writes, reactive sync, minimal boilerplate
- **Sacrifice**: Smaller community than SQLite, less raw query control, needing code generation step
