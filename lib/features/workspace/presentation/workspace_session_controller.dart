import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../intelligence/application/intelligence_brain.dart';
import '../../intelligence/application/intelligence_engine.dart';
import '../data/repositories/workspace_repository.dart';
import '../domain/models/workspace_session_detail.dart';
import '../domain/models/workspace_session_message.dart';
import '../domain/models/workspace_task.dart';

/// Owns the state for a single session detail screen.
///
/// Mutations go through the shared [WorkspaceRepository] so changes made here
/// (pin, archive, delete, messages) are visible to the workspace screen after
/// the screen pops and refreshes.
///
/// When an [engine] is supplied, new messages are bridged into the Intelligence
/// Brain (RAG + memory + workspace tools + the configured LLM provider) and the
/// reply is written back as an AI message. Without an engine the legacy mock
/// session stack is used unchanged, so existing screens and tests keep working.
class WorkspaceSessionController extends ChangeNotifier {
  WorkspaceSessionController({
    required this.repository,
    required this.sessionId,
    this.engine,
    this.replyDelay = const Duration(milliseconds: 600),
  }) {
    _detail = repository.loadSessionDetail(sessionId);
  }

  final WorkspaceRepository repository;
  final String sessionId;

  /// Optional brain-backed stack. Null keeps the mock reply path.
  final IntelligenceEngine? engine;

  final Duration replyDelay;

  late WorkspaceSessionDetail _detail;
  bool _isSending = false;
  bool _disposed = false;

  WorkspaceSessionDetail get detail => _detail;

  /// True while the AI is "typing" a reply.
  bool get isSending => _isSending;

  Future<void> sendMessage(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty || _isSending) return;
    _isSending = true;
    notifyListeners();
    try {
      final brain = engine?.brain;
      if (brain != null) {
        // Brain-backed path: persist the user turn, run the full pipeline
        // (RAG + memory + tools + LLM), then write the reply back.
        _detail =
            repository.addSessionMessage(sessionId, MessageAuthor.user, text);
        final reply = await _runBrain(brain, text);
        if (_disposed) return;
        _detail = repository.addSessionMessage(
          sessionId,
          MessageAuthor.ai,
          reply,
        );
      } else {
        // Legacy mock path, unchanged.
        await Future<void>.delayed(replyDelay);
        if (_disposed) return;
        _detail = repository.sendMessage(sessionId, text);
      }
    } finally {
      _isSending = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Runs one brain turn, degrading gracefully when the LLM is unreachable so
  /// the session screen never breaks.
  Future<String> _runBrain(IntelligenceBrain brain, String text) async {
    try {
      final result = await brain.chat(
        conversationId: sessionId,
        userMessage: text,
      );
      return result.text;
    } catch (_) {
      return "I couldn't reach the local AI model. "
          'Make sure Ollama is running and the model is loaded.';
    }
  }

  Future<void> regenerateReply() async {
    if (_isSending) return;
    _isSending = true;
    notifyListeners();
    await Future<void>.delayed(replyDelay);
    if (_disposed) return;
    _detail = repository.regenerateReply(sessionId);
    _isSending = false;
    notifyListeners();
  }

  void rename(String newTitle) {
    final title = newTitle.trim();
    if (title.isEmpty || title == _detail.session.title) return;
    _detail = repository.renameSession(sessionId, title);
    notifyListeners();
  }

  void togglePinned() {
    repository.setSessionPinned(sessionId, !_detail.session.pinned);
    _detail = repository.loadSessionDetail(sessionId);
    notifyListeners();
  }

  void toggleArchived() {
    repository.setSessionArchived(sessionId, !_detail.session.archived);
    _detail = repository.loadSessionDetail(sessionId);
    notifyListeners();
  }

  void deleteSession() {
    repository.deleteSession(sessionId);
    notifyListeners();
  }

  /// Turns an action item into a real workspace task (linked to this session).
  void checkActionItem(int index) {
    if (index < 0 || index >= _detail.actionItems.length) return;
    final item = _detail.actionItems[index];
    repository.addTasks([
      WorkspaceTask(
        id: 'task-$sessionId-$index',
        title: item,
        done: false,
        priority: TaskPriority.medium,
        source: TaskSource.ai,
        linkedSessionIds: const [],
        linkedFileIds: const [],
      ),
    ]);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
