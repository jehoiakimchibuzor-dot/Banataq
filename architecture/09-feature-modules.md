# Feature Module Architecture

## Module Structure

Instead of a monolithic app, each feature is an independent module with its own:

```
features/{feature}/
+-- data/
|   +-- datasources/
|   +-- repositories/
+-- domain/
|   +-- entities/
|   +-- repositories/   (abstract interfaces)
|   +-- usecases/
+-- presentation/
|   +-- blocs/
|   +-- screens/
|   +-- widgets/
+-- module_di.dart       (dependency injection setup)
```

## Module Registry

```dart
// Core module registry — each module self-registers
abstract class BanataqModule {
  String get name;
  List<RouteBase> get routes;
  List<SingleChildWidget> get providers;
  Map<String, dynamic> get capabilities;
}

// Example: ChatModule
class ChatModule implements BanataqModule {
  @override
  String get name => 'chat';

  @override
  List<RouteBase> get routes => [
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/chat/:id', builder: (_, state) => ChatScreen(convId: state.pathParameters['id'])),
  ];

  @override
  List<SingleChildWidget> get providers => [
    BlocProvider<ChatBloc>(create: (_) => ChatBloc()),
  ];

  @override
  Map<String, dynamic> get capabilities => {
    'send_message': true,
    'stream_response': true,
    'save_answer': true,
  };
}
```

## Module List

| Module | Dependencies | Status | Priority |
|--------|-------------|--------|----------|
| `core` | None | Foundation | P0 |
| `auth` | `core` | Foundation | P0 |
| `chat` | `core`, `ai` | Foundation | P0 |
| `settings` | `core` | Foundation | P0 |
| `ai` | `core` | Foundation | P0 |
| `memory` | `core` | P1 |
| `files` | `core`, `storage` | P1 |
| `voice` | `core` | P1 |
| `vision` | `core`, `ai` | P2 |
| `learn` | `core`, `ai`, `files` | P2 |
| `business` | `core`, `ai` | P3 |
| `tasks` | `core` | P3 |
| `agents` | `core`, `ai`, `memory` | P4 |

## Module Communication

Modules communicate through:
1. **Repository interfaces** (defined in `core`) — e.g., `MemoryRepository` used by `chat` module
2. **Shared events** (via BLoC) — e.g., `chat` module emits `MessageSent`, `learn` module listens
3. **Service locator** (GetIt/Injection) — modules register their services, others import interfaces

**Key rule**: Modules can depend on `core` and interfaces. They should NOT import another module's implementation directly.
