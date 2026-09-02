import 'package:http/http.dart' as http;

import '../../../core/design_system/design_system.dart';
import '../../workspace/data/repositories/workspace_repository.dart';
import '../../workspace/domain/models/workspace_memory.dart';
import '../data/providers/ollama_llm_provider.dart';
import '../domain/models/rag_document.dart';
import '../domain/models/tool_call.dart';
import '../domain/models/tool_definition.dart';
import '../domain/providers/llm_provider.dart';
import '../domain/providers/tool_runner.dart';
import 'intelligence_engine.dart';
import 'rag_engine.dart';

/// Bridges the Workspace module into the Intelligence Layer.
///
/// 1. Exposes workspace content (files, memories, sessions, timeline) as RAG
///    documents so the brain can ground answers in real workspace knowledge.
/// 2. Registers workspace tools (search, memories, tasks, files, briefing) so
///    the model can *act* on the workspace, not just read it.
class WorkspaceKnowledgeAdapter {
  WorkspaceKnowledgeAdapter(this.repository);

  final WorkspaceRepository repository;

  /// Builds one [RagDocument] per workspace item.
  List<RagDocument> buildDocuments() {
    final documents = <RagDocument>[];

    for (final file in repository.loadFiles()) {
      documents.add(
        RagDocument(
          id: 'file-${file.id}',
          title: file.name,
          content: [
            'File: ${file.name}',
            'Keywords: ${file.name.replaceAll(RegExp(r'[^a-z0-9]+'), ' ')}',
            'Type: ${file.type.label}',
            ?file.summary,
            ?file.meta,
            if (file.favourite) 'Marked favourite',
            if (file.pinned) 'Pinned',
          ].join('\n'),
          source: 'file',
        ),
      );
    }

    for (final memory in repository.loadMemories()) {
      documents.add(
        RagDocument(
          id: 'memory-${memory.id}',
          title: memory.title,
          content: '${memory.title}: ${memory.content} (${memory.category.label})',
          source: 'memory',
        ),
      );
    }

    for (final session in repository.loadSessions()) {
      documents.add(
        RagDocument(
          id: 'session-${session.id}',
          title: session.title,
          content: [
            'Session: ${session.title}',
            ?session.purpose,
            ?session.preview,
            ?session.summary,
          ].join('\n'),
          source: 'session',
        ),
      );
    }

    for (final event in repository.loadTimeline()) {
      documents.add(
        RagDocument(
          id: 'timeline-${event.id}',
          title: event.title,
          content: '${event.title}: ${event.description ?? ''}',
          source: 'timeline',
        ),
      );
    }

    return documents;
  }

  /// Indexes the whole workspace into the RAG store.
  Future<void> indexInto(RagEngine rag) async {
    for (final document in buildDocuments()) {
      await rag.index(document);
    }
  }

  /// One-line summary of what is in the workspace knowledge base.
  String buildBriefing() {
    final files = repository.loadFiles();
    final memories = repository.loadMemories();
    final sessions = repository.loadSessions();
    final tasks = repository.loadTasks();
    final done = tasks.where((t) => t.done).length;
    return 'Workspace knowledge base: ${files.length} files, '
        '${memories.length} memories, ${sessions.length} sessions, '
        '$done/${tasks.length} tasks done.';
  }
}

/// Builds a brain that knows how to read and act on a specific workspace.
class WorkspaceBrainFactory {
  /// Creates an engine, indexes the workspace into RAG and registers the
  /// workspace tool set.
  static Future<IntelligenceEngine> build({
    WorkspaceRepository? repository,
    LlmProvider? provider,
  }) async {
    final repo = repository ?? MockWorkspaceRepository();
    final engine = IntelligenceEngine.offline(provider: provider);
    await WorkspaceKnowledgeAdapter(repo).indexInto(engine.rag);
    registerWorkspaceTools(engine.toolRunner, repo);
    return engine;
  }

  /// Builds a brain backed by the local Ollama model (qwen2.5:3b).
  ///
  /// No network call happens here — the adapter connects lazily on the first
  /// `chat`, so building is always safe even when Ollama is offline.
  static Future<IntelligenceEngine> buildWithOllama({
    WorkspaceRepository? repository,
    String? baseUrl,
    String? model,
    http.Client? client,
  }) async {
    final provider = OllamaLlmProvider(
      baseUrl: baseUrl,
      model: model,
      client: client,
    );
    return build(repository: repository, provider: provider);
  }

  /// Registers tools that operate on [repository].
  static void registerWorkspaceTools(
    ToolRunner toolRunner,
    WorkspaceRepository repository,
  ) {
    toolRunner.register(
      const ToolDefinition(
        name: 'search_workspace',
        description:
            'Search the current workspace for sessions, tasks, files and memories matching a query.',
        parameters: {
          'type': 'object',
          'properties': {'query': {'type': 'string'}},
        },
      ),
      (call) async {
        final query = _queryOf(call, 'search_workspace');
        final results = repository.search(query);
        final lines = <String>[
          for (final s in results.sessions) 'Session: ${s.title}',
          for (final t in results.tasks) 'Task: ${t.title}',
          for (final f in results.files) 'File: ${f.name}',
          for (final m in results.memories) 'Memory: ${m.title}',
        ];
        return lines.isEmpty ? 'No matches for "$query".' : lines.join('\n');
      },
    );

    toolRunner.register(
      const ToolDefinition(
        name: 'list_files',
        description: 'List every file in the workspace.',
        parameters: {'type': 'object', 'properties': {}},
      ),
      (call) async {
        final files = repository.loadFiles();
        return files.isEmpty
            ? 'No files yet.'
            : files.map((f) => '- ${f.name} (${f.type.label})').join('\n');
      },
    );

    toolRunner.register(
      const ToolDefinition(
        name: 'get_memories',
        description: 'Read long-term memories stored in the workspace.',
        parameters: {
          'type': 'object',
          'properties': {'query': {'type': 'string'}},
        },
      ),
      (call) async {
        final query = _queryOf(call, 'get_memories');
        final memories = repository.loadMemories().where(
              (m) =>
                  query.isEmpty ||
                  m.title.toLowerCase().contains(query) ||
                  m.content.toLowerCase().contains(query),
            );
            return memories.isEmpty
                ? 'No memories found.'
                : memories.map((m) => '- $m.title: $m.content').join('\n');
      },
    );

    toolRunner.register(
      const ToolDefinition(
        name: 'complete_task',
        description: 'Mark a workspace task as done or pending.',
        parameters: {
          'type': 'object',
          'properties': {
            'taskId': {'type': 'string'},
            'done': {'type': 'boolean'},
          },
          'required': ['taskId', 'done'],
        },
      ),
      (call) async {
        final tasks = repository.loadTasks();
        if (tasks.isEmpty) return 'No tasks in the workspace.';
        final requestedId = call.arguments['taskId']?.toString() ?? '';
        final query = _queryOf(call, 'complete_task').toLowerCase();
        final done = call.arguments['done'] as bool? ?? true;
        final task = tasks.firstWhere(
          (t) =>
              t.id == requestedId ||
              (query.isNotEmpty && t.title.toLowerCase().contains(query)),
          orElse: () => tasks.first,
        );
        repository.setTaskDone(task.id, done);
        return 'Task "${task.title}" marked ${done ? 'done' : 'pending'}.';
      },
    );

    toolRunner.register(
      const ToolDefinition(
        name: 'summarize_file',
        description: 'Generate an AI summary for a workspace file.',
        parameters: {
          'type': 'object',
          'properties': {
            'fileId': {'type': 'string'},
          },
          'required': ['fileId'],
        },
      ),
      (call) async {
        final files = repository.loadFiles();
        if (files.isEmpty) return 'No files in the workspace.';
        final query = _queryOf(call, 'summarize_file').toLowerCase();
        final requestedId = call.arguments['fileId']?.toString() ?? '';
        final file = files.firstWhere(
          (f) =>
              f.id == requestedId || f.name.toLowerCase().contains(query),
          orElse: () => files.first,
        );
        final summarized = repository.summarizeFile(file.id);
        return 'Summarized ${summarized.name}: ${summarized.summary}';
      },
    );

    toolRunner.register(
      const ToolDefinition(
        name: 'workspace_briefing',
        description: 'Get a snapshot of the current workspace contents.',
        parameters: {'type': 'object', 'properties': {}},
      ),
      (call) async {
        return WorkspaceKnowledgeAdapter(repository).buildBriefing();
      },
    );
  }

  /// The mock provider passes the whole user message as `query`; strip the
  /// tool name so the executor gets the meaningful search text.
  static String _queryOf(ToolCall call, String toolName) {
    final raw = call.arguments['query']?.toString() ?? '';
    return raw.replaceAll(toolName, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
