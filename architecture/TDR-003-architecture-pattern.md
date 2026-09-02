# TDR-003: Architecture Pattern

**Date**: 2026-07-27
**Version**: 1.0.0

## Decision
Use **Clean Architecture** with 3 layers (data / domain / presentation).

## Alternatives Considered
1. **MVVM (Model-View-ViewModel)** — Simpler, less abstraction. Tighter coupling, harder to swap implementations, no clear use-case layer.
2. **MVI (Model-View-Intent)** — Similar to BLoC, great for reactive flows. Less established in Flutter, fewer examples.
3. **Clean Architecture** — Strict dependency inversion, use-case-centric, highly testable, proven at scale.

## Reasoning
- Dependency inversion means the AI layer, sync engine, and storage can be swapped without touching UI
- Use cases encapsulate business logic (e.g., SendMessageUseCase coordinates: save local, queue sync, call AI, persist response)
- Domain layer has zero Flutter dependencies, making it testable on Dart VM alone
- Scales well to 100+ files and multiple contributors
- Each feature module follows the same 3-layer structure, reducing cognitive load

## Trade-offs
- **Gain**: Maximum testability, clear boundaries, swap-friendly
- **Sacrifice**: More files per feature, longer initial implementation, overkill for very simple features
