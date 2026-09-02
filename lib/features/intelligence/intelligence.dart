/// Banataq Intelligence Layer — the AI operating-system core.
///
/// Public surface for the module. The layer is organised by clean-architecture
/// tiers:
/// * `domain/models`     — immutable data types
/// * `domain/providers`  — abstract contracts (LLM, memory, RAG, tools, ...)
/// * `data/providers`    — concrete offline/remote implementations
/// * `application`       — the orchestrating Brain and engines
library;

export 'application/context_compressor_impl.dart';
export 'application/intelligence_brain.dart';
export 'application/intelligence_engine.dart';
export 'application/llm_provider_factory.dart';
export 'application/prompt_assembler_impl.dart';
export 'application/rag_engine.dart';
export 'application/simple_memory_extractor.dart';
export 'application/tool_runner_impl.dart';
export 'application/workspace_knowledge_adapter.dart';

export 'data/providers/gemini_llm_provider.dart';
export 'data/providers/hashing_embedding_generator.dart';
export 'data/providers/in_memory_chat_history_store.dart';
export 'data/providers/in_memory_memory_store.dart';
export 'data/providers/in_memory_vector_store.dart';
export 'data/providers/local_llm_provider.dart';
export 'data/providers/mock_llm_provider.dart';
export 'data/providers/ollama_llm_provider.dart';
export 'data/providers/openai_llm_provider.dart';
export 'data/providers/persistent_chat_history_store.dart';
export 'data/providers/persistent_memory_store.dart';
export 'data/providers/simple_tokenizer.dart';

export 'domain/models/assembled_context.dart';
export 'domain/models/brain_reply.dart';
export 'domain/models/chat_usage.dart';
export 'domain/models/compressed_context.dart';
export 'domain/models/intelligence_message.dart';
export 'domain/models/llm_provider_type.dart';
export 'domain/models/llm_request.dart';
export 'domain/models/llm_response.dart';
export 'domain/models/llm_stream_event.dart';
export 'domain/models/long_term_memory.dart';
export 'domain/models/rag_chunk.dart';
export 'domain/models/rag_document.dart';
export 'domain/models/tool_call.dart';
export 'domain/models/tool_definition.dart';
export 'domain/models/tool_result.dart';
export 'domain/models/vector_match.dart';

export 'domain/providers/chat_history_store.dart';
export 'domain/providers/context_compressor.dart';
export 'domain/providers/embedding_generator.dart';
export 'domain/providers/llm_provider.dart';
export 'domain/providers/memory_extractor.dart';
export 'domain/providers/memory_store.dart';
export 'domain/providers/prompt_assembler.dart';
export 'domain/providers/tokenizer.dart';
export 'domain/providers/tool_runner.dart';
export 'domain/providers/vector_store.dart';
