/// Token accounting for a single LLM round trip.
class ChatUsage {
  const ChatUsage({required this.promptTokens, required this.completionTokens});

  final int promptTokens;
  final int completionTokens;

  int get totalTokens => promptTokens + completionTokens;

  static const empty = ChatUsage(promptTokens: 0, completionTokens: 0);

  ChatUsage operator +(ChatUsage other) => ChatUsage(
        promptTokens: promptTokens + other.promptTokens,
        completionTokens: completionTokens + other.completionTokens,
      );
}
