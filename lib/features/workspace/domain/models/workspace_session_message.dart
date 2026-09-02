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
}
