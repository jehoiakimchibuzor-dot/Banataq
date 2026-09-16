/// Who wrote a message in a session.
enum MessageAuthor { user, ai }

/// A single turn in a working session.
class WorkspaceSessionMessage {
  const WorkspaceSessionMessage({
    required this.id,
    required this.author,
    required this.text,
    this.sentAt,
  });

  final String id;
  final MessageAuthor author;
  final String text;
  final DateTime? sentAt;

  bool get fromAi => author == MessageAuthor.ai;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.name,
        'text': text,
        'sentAt': sentAt?.toIso8601String(),
      };

  factory WorkspaceSessionMessage.fromJson(Map<String, dynamic> json) {
    return WorkspaceSessionMessage(
      id: json['id'] as String? ?? '',
      author: MessageAuthor.values.firstWhere(
        (e) => e.name == json['author'],
        orElse: () => MessageAuthor.user,
      ),
      text: json['text'] as String? ?? '',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null,
    );
  }
}
