# TDR-002: State Management

**Date**: 2026-07-27
**Version**: 1.0.0

## Decision
Use **flutter_bloc (BLoC)** for state management.

## Alternatives Considered
1. **Riverpod** — Modern, less boilerplate than BLoC, no context dependency. Less established pattern enforcement, harder to trace complex flows.
2. **Provider** — Simple, built into Flutter ecosystem. Insufficient for complex state, no built-in event/state separation.
3. **GetX** — Minimal boilerplate, high performance. Poor community reputation, anti-pattern encouragement, hard to debug.
4. **BLoC** — Clear separation of events/states, testable, well-documented, widely adopted in production Flutter apps.

## Reasoning
- The app has complex state: auth, sync, chat, memory, multiple AI providers
- BLoC's event/state model maps well to the sync engine's queue-based architecture
- BLoC is highly testable with bloc_test, critical for reliability
- Clear "one event, one state transition" makes the sync flow auditable
- Large community, abundant examples, good debugging tools (BlocObserver)

## Trade-offs
- **Gain**: Testable, auditable, predictable state flow; strong separation of concerns
- **Sacrifice**: More boilerplate than Riverpod; steeper learning curve for new contributors
