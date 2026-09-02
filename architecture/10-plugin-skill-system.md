# Plugin / Skill System

## Philosophy

Don't hardcode every capability. Define a plugin interface that any skill can implement. New skills can be added without touching the core app.

## Plugin Interface

```dart
abstract class BanataqSkill {
  /// Unique identifier
  String get id;

  /// Display name
  String get name;

  /// Icon for UI
  IconData get icon;

  /// Short description
  String get description;

  /// Whether this skill modifies the system prompt
  String? get systemPromptOverride;

  /// Tools/functions this skill provides
  List<AiFunction> get tools;

  /// Capabilities this skill advertises (used by model router)
  List<SkillCapability> get capabilities;

  /// Optional configuration screen
  Widget? get settingsWidget;

  /// Called when skill is activated/deactivated
  Future<void> onActivate(String userId);
  Future<void> onDeactivate(String userId);
}
```

## Built-in Skills

| Skill | ID | Capabilities | Phase |
|-------|----|-------------|-------|
| General Chat | `general` | Text, Q&A | P0 |
| Study Assistant | `tutor` | Quiz, Flashcards, Summaries | P2 |
| PDF Expert | `pdf` | Extract, Summarize, Translate | P3 |
| Vision | `vision` | Image analysis, OCR | P3 |
| Business | `business` | Invoices, Captions, Proposals | P3 |
| Code Assistant | `coder` | Code gen, Debug, Explain | P4 |
| Translator | `translate` | Hausa, Yoruba, Igbo, English | P4 |
| Agent Mode | `agent` | Multi-step tasks, Tool execution | P4 |

## Skill Selector UI

```
[General Chat] [Tutor] [PDF] [Vision] [Business] [Code]  <- Tab bar
                                                              (tabs are skills)
Selected skill changes:
  - System prompt (skill-specific instructions)
  - Available tools/functions
  - Model routing preference
  - UI hints (e.g., PDF skill shows file upload button)
```

## Skill Marketplace (Future — Phase 7)

```dart
// Skills are downloadable, not just built-in
class SkillStore {
  Future<List<BanataqSkill>> fetchAvailableSkills(String userId);
  Future<void> installSkill(String skillId);
  Future<void> uninstallSkill(String skillId);
  Future<void> updateSkill(String skillId);
}

// Skills can be community-contributed (future)
// Each skill is a package with:
//   - manifest.json (id, name, description, version, permissions)
//   - main.dart (implements BanataqSkill)
//   - assets/ (icons, prompts, templates)
```
