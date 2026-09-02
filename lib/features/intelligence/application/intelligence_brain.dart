import 'dart:async';

import '../data/providers/simple_tokenizer.dart';
import '../domain/models/assembled_context.dart';
import '../domain/models/brain_reply.dart';
import '../domain/models/chat_usage.dart';
import '../domain/models/intelligence_message.dart';
import '../domain/models/llm_request.dart';
import '../domain/models/llm_stream_event.dart';
import '../domain/models/long_term_memory.dart';
import '../domain/models/rag_chunk.dart';
import '../domain/models/tool_call.dart';
import '../domain/models/tool_result.dart';
import '../domain/providers/chat_history_store.dart';
import '../domain/providers/llm_provider.dart';
import '../domain/providers/memory_extractor.dart';
import '../domain/providers/memory_store.dart';
import '../domain/providers/prompt_assembler.dart';
import '../domain/providers/tokenizer.dart';
import '../domain/providers/tool_runner.dart';
import 'rag_engine.dart';
import 'simple_memory_extractor.dart';

/// The AI Brain — the orchestrator of the Intelligence Layer.
///
/// One [chat] / [streamChat] turn runs the full intelligence pipeline:
/// 1. Store the user turn in short-term conversation memory.
/// 2. Recall relevant long-term memories (keyword + importance fallback).
/// 3. Retrieve grounding knowledge via RAG.
/// 4. Assemble & compress the prompt (memories + knowledge + tools + history).
/// 5. Call the model; if it requests tools, execute them and loop up to
///    [maxToolIterations] times.
/// 6. Extract new long-term memories from the turn.
/// 7. Persist the assistant reply to conversation memory.
class IntelligenceBrain {
  IntelligenceBrain({
    required this.provider,
    required this.assembler,
    required this.memoryStore,
    required this.historyStore,
    required this.rag,
    required this.toolRunner,
    Tokenizer? tokenizer,
    MemoryExtractor? memoryExtractor,
    this.maxToolIterations = 4,
    this.systemInstructions,
  })  : tokenizer = tokenizer ?? const SimpleTokenizer(),
        memoryExtractor = memoryExtractor ?? const SimpleMemoryExtractor();

  final LlmProvider provider;
  final PromptAssembler assembler;
  final MemoryStore memoryStore;
  final ChatHistoryStore historyStore;
  final RagEngine rag;
  final ToolRunner toolRunner;
  final Tokenizer tokenizer;
  final MemoryExtractor memoryExtractor;
  final int maxToolIterations;
  final String? systemInstructions;

  /// Runs one full intelligence turn and returns the final [BrainReply].
  Future<BrainReply> chat({
    required String conversationId,
    required String userMessage,
    String? persona,
    int tokenBudget = 4096,
  }) async {
    final started = DateTime.now();
    final userMsg =
        IntelligenceMessage(role: IntelligenceRole.user, content: userMessage);
    await historyStore.append(conversationId, userMsg);

    final memories = await _recall(userMessage);
    final documents = await rag.retrieve(userMessage, limit: 4);
    final assembled = await _assemble(
      conversationId: conversationId,
      userMsg: userMsg,
      persona: persona,
      memories: memories,
      documents: documents,
      tokenBudget: tokenBudget,
    );

    var messages = assembled.messages;
    var usage = ChatUsage.empty;
    var iterations = 0;
    final toolResults = <ToolResult>[];
    var finalText = '';
    var lastContent = '';

    while (iterations < maxToolIterations) {
      iterations++;
      final response = await provider.complete(
        LlmRequest(
          systemPrompt: assembled.systemPrompt,
          messages: messages,
          tools: toolRunner.definitions,
        ),
      );
      usage += response.usage;
      lastContent = response.content;
      if (!response.hasToolCalls) {
        finalText = response.content;
        break;
      }
      final results = await toolRunner.executeAll(response.toolCalls);
      toolResults.addAll(results);
      messages = [
        ...messages,
        IntelligenceMessage(
          role: IntelligenceRole.assistant,
          content: response.content,
        ),
        for (final result in results)
          IntelligenceMessage(
            role: IntelligenceRole.tool,
            content: result.asToolMessage(),
            toolCallId: result.toolCallId,
          ),
      ];
      if (results.isNotEmpty && results.every((r) => r.isError)) {
        finalText = lastContent;
        break;
      }
    }

    await _persistTurn(
      conversationId: conversationId,
      userText: userMessage,
      assistantText: finalText,
    );

    return BrainReply(
      text: finalText,
      sources: documents,
      memoriesUsed: memories,
      toolResults: toolResults,
      usage: usage,
      iterations: iterations,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
    );
  }

  /// Streaming variant: emits text deltas as they arrive and still runs the
  /// full tool loop and memory pipeline.
  Stream<String> streamChat({
    required String conversationId,
    required String userMessage,
    String? persona,
    int tokenBudget = 4096,
  }) async* {
    final userMsg =
        IntelligenceMessage(role: IntelligenceRole.user, content: userMessage);
    await historyStore.append(conversationId, userMsg);

    final memories = await _recall(userMessage);
    final documents = await rag.retrieve(userMessage, limit: 4);
    final assembled = await _assemble(
      conversationId: conversationId,
      userMsg: userMsg,
      persona: persona,
      memories: memories,
      documents: documents,
      tokenBudget: tokenBudget,
    );

    var messages = assembled.messages;
    var iterations = 0;
    var finalText = '';

    while (iterations < maxToolIterations) {
      iterations++;
      final buffer = StringBuffer();
      final toolCalls = <ToolCall>[];
      await for (final event in provider.stream(
        LlmRequest(
          systemPrompt: assembled.systemPrompt,
          messages: messages,
          tools: toolRunner.definitions,
        ),
      )) {
        switch (event) {
          case LlmTextDelta(:final text):
            buffer.write(text);
            yield text;
          case LlmToolCallEvent(:final call):
            toolCalls.add(call);
          case LlmDoneEvent():
            break;
        }
      }
      final text = buffer.toString();
      if (toolCalls.isEmpty) {
        finalText = text;
        break;
      }
      final results = await toolRunner.executeAll(toolCalls);
      messages = [
        ...messages,
        IntelligenceMessage(role: IntelligenceRole.assistant, content: text),
        for (final result in results)
          IntelligenceMessage(
            role: IntelligenceRole.tool,
            content: result.asToolMessage(),
            toolCallId: result.toolCallId,
          ),
      ];
      if (results.isNotEmpty && results.every((r) => r.isError)) {
        finalText = text;
        break;
      }
    }

    await _persistTurn(
      conversationId: conversationId,
      userText: userMessage,
      assistantText: finalText,
    );
  }

  /// Explicitly stores a memory the app (or user) wants remembered.
  Future<void> remember(LongTermMemory memory) => memoryStore.add(memory);

  /// Direct recall over long-term memory.
  Future<List<LongTermMemory>> recall(String query, {int limit = 10}) =>
      memoryStore.search(query, limit: limit);

  Future<List<LongTermMemory>> _recall(String query, {int limit = 4}) async {
    final matches = await memoryStore.search(query, limit: limit);
    if (matches.isNotEmpty) {
      for (final memory in matches) {
        await memoryStore.touch(memory.id);
      }
      return matches;
    }
    final fallback = await memoryStore.important(limit: limit);
    for (final memory in fallback) {
      await memoryStore.touch(memory.id);
    }
    return fallback;
  }

  Future<AssembledContext> _assemble({
    required String conversationId,
    required IntelligenceMessage userMsg,
    required String? persona,
    required List<LongTermMemory> memories,
    required List<RagChunk> documents,
    required int tokenBudget,
  }) async {
    final history = await historyStore.messages(conversationId, limit: 20);
    final priorHistory = history.length > 1
        ? history.sublist(0, history.length - 1)
        : const <IntelligenceMessage>[];
    return assembler.assemble(
      AssemblerInput(
        userMessage: userMsg,
        persona: persona,
        systemInstructions: systemInstructions,
        history: priorHistory,
        memories: memories,
        documents: documents,
        tools: toolRunner.definitions,
        tokenBudget: tokenBudget,
      ),
    );
  }

  Future<void> _persistTurn({
    required String conversationId,
    required String userText,
    required String assistantText,
  }) async {
    final extracted = memoryExtractor.extract(userText);
    if (extracted.isNotEmpty) {
      await memoryStore.addAll(extracted);
    }
    await historyStore.append(
      conversationId,
      IntelligenceMessage(role: IntelligenceRole.assistant, content: assistantText),
    );
  }
}
