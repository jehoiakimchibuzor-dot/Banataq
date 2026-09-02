enum MessageFeedback { liked, disliked }

class ChatMessage {
  final String id;
  final bool fromUser;
  String text;
  bool isStreaming;
  MessageFeedback? feedback;
  bool pinned;

  ChatMessage({
    String? id,
    required this.fromUser,
    required this.text,
    this.isStreaming = false,
    this.feedback,
    this.pinned = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ChatMessage copyWith({
    String? id,
    bool? fromUser,
    String? text,
    bool? isStreaming,
    MessageFeedback? feedback,
    bool? pinned,
    bool clearFeedback = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      fromUser: fromUser ?? this.fromUser,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUser': fromUser,
    'text': text,
    if (feedback != null) 'feedback': feedback!.name,
    if (pinned) 'pinned': true,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String?,
    fromUser: json['fromUser'] as bool,
    text: json['text'] as String,
    feedback: json['feedback'] != null
        ? MessageFeedback.values.firstWhere((e) => e.name == json['feedback'])
        : null,
    pinned: json['pinned'] as bool? ?? false,
  );
}
