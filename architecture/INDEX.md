# Banataq Architecture — Index

## Architecture Review Documents

| File | Contents |
|------|----------|
| `01-identity-and-system.md` | Identity document, system architecture, Firestore schema (7 collections) |
| `02-data-models-and-folder-structure.md` | Dart models, Clean Architecture folder structure |
| `03-security-auth-sync.md` | Security rules, auth flows (Google/Email/Apple/Anonymous), cloud sync strategy |
| `04-ai-layer-and-sequence-diagrams.md` | AI provider abstraction, sequence diagrams (auth + chat sync), Isar local DB, analytics, error handling |
| `05-implementation-plan.md` | 9 phases with acceptance criteria, dependencies, performance targets |
| `06-scalability.md` | Firestore cost estimates (10K to 1M users), chat document sizing, pagination, indexing strategy, scaling plan |
| `07-ai-layer.md` | Full AI pipeline (provider -> model router -> tools -> streaming -> memory -> RAG -> agent), cost management, model routing with fallback |
| `08-memory-architecture.md` | 5-layer memory system (profile, long-term, short-term, session, project) with distinct lifecycles |
| `09-feature-modules.md` | Modular architecture with self-registering `BanataqModule` interface, module dependency rules |
| `10-plugin-skill-system.md` | Plugin/skill interface, built-in skill list, skill selector UI, future marketplace |
| `11-remote-config.md` | Firebase Remote Config for feature flags, prompt templates, provider config, maintenance mode |
| `12-security-review.md` | Secrets management, API key rotation, encryption, abuse prevention, prompt injection protection, file validation, audit logging, compliance |
| `13-approved-phase-1.md` | APPROVED Phase 1 scope: Auth + Profile + Cloud Sync + Settings only. Explicit exclusions. Step-by-step implementation order (7 steps, 10 days). Acceptance criteria gate. |
| `TDR-INDEX.md` | Technical Decision Records index |
| `TDR-001-database.md` | TDR: Isar vs Drift vs Hive vs SQLite |
| `TDR-002-state-management.md` | TDR: BLoC vs Riverpod vs Provider vs GetX |
| `TDR-003-architecture-pattern.md` | TDR: Clean Architecture vs MVVM vs MVI |
| `TDR-004-cloud-platform.md` | TDR: Firebase vs Supabase vs Custom Backend |
| `TDR-005-sync-strategy.md` | TDR: Offline-First vs Online-Only |

## Review Responses

### 1. Scalability
Firestore cost estimates at 10K/100K/1M users, message sharding strategy (latest 50 inline + subcollection archive), cursor-based pagination, composite index specification, and scaling roadmap. See `06-scalability.md`.

### 2. AI Layer
Complete pipeline: Provider -> Model Router (resolves by task type) -> Tool Resolver -> Streaming -> Memory Injection -> RAG Engine -> Agent Runtime. See `07-ai-layer.md`.

### 3. Memory
5 distinct memory types with separate lifecycles: User Profile (permanent), Long-term (until deleted), Short-term (conversation-scoped), Session (runtime-only), Project (timed). Extractor auto-discovers memories from conversations. See `08-memory-architecture.md`.

### 4. Feature Modules
Modular `BanataqModule` interface. Each feature is self-contained with its own data/domain/presentation layers, routes, and BLoC providers. Modules communicate through repository interfaces and shared events, never direct imports. See `09-feature-modules.md`.

### 5. AI Cost Management
Token usage tracking per session/user, cost estimation per model, provider fallback chain, rate limiting, model routing by task type (simple -> cheap, coding -> best, etc.). Budget enforcement. See `07-ai-layer.md`.

### 6. Remote Configuration
Firebase Remote Config for feature flags, prompt templates, enabled providers, model routing, rate limits, maintenance mode, experimental features. No app store update needed for configuration changes. See `11-remote-config.md`.

### 7. Plugin/Skill System
`BanataqSkill` interface with 8 planned skills. Skills modify system prompt, tools, and model routing. Tab-based skill selector. Future skill marketplace with install/uninstall/update. See `10-plugin-skill-system.md`.

### 8. Security Review
Secrets management (flutter_secure_storage AES-256), key rotation flow, encryption strategy (device + transit + server), abuse prevention (rate limiting, blocklists, file validation), prompt injection protection (delimiters, max length, sanitization), file validation (magic bytes, anti-spoofing, PDF JS detection, EXIF stripping), audit logging, GDPR considerations. See `12-security-review.md`.

### TDRs
5 Technical Decision Records covering the major architectural choices with alternatives, reasoning, and trade-offs.

## Phase 1: Approved

**Scope**: Authentication (Google, Email, Anonymous, Apple-ready) + User Profile + Cloud Sync + Settings.

**Explicitly excluded**: Voice, Vision, Files, Memory, Student features, Business tools, Skills, Agents.

**Duration**: ~10 days, 7 implementation steps.

**Gate**: 19 acceptance criteria must pass before Phase 2 begins.

See `13-approved-phase-1.md` for the full implementation plan.
