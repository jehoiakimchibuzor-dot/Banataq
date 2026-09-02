import 'chat_message.dart';

class Conversation {
  final String id;
  String title;
  List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  bool pinned;
  DateTime? pinnedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    DateTime? updatedAt,
    this.pinned = false,
    this.pinnedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Conversation copyWith({String? title, bool? pinned, DateTime? pinnedAt}) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      messages: messages,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pinned: pinned ?? this.pinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (pinned) 'pinned': true,
    if (pinnedAt != null) 'pinnedAt': pinnedAt!.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String,
    messages: (json['messages'] as List)
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    pinned: json['pinned'] as bool? ?? false,
    pinnedAt: json['pinnedAt'] != null
        ? DateTime.parse(json['pinnedAt'] as String)
        : null,
  );
}
