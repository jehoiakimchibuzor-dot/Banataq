import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart' as model;

class MessageActions extends StatelessWidget {
  final model.ChatMessage message;
  final VoidCallback onSave;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onRegenerate;

  const MessageActions({
    super.key,
    required this.message,
    required this.onSave,
    required this.onLike,
    required this.onDislike,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(scheme, Icons.copy_rounded, 'Copy', () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
            );
          }),
          const SizedBox(width: 2),
          _icon(scheme, Icons.share_rounded, 'Share', () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
            );
          }),
          const SizedBox(width: 2),
          _icon(scheme, Icons.bookmark_border_rounded, 'Save', onSave),
          const SizedBox(width: 2),
          _icon(
            scheme,
            message.feedback == model.MessageFeedback.liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            'Like', onLike,
            active: message.feedback == model.MessageFeedback.liked,
          ),
          const SizedBox(width: 2),
          _icon(
            scheme,
            message.feedback == model.MessageFeedback.disliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
            'Dislike', onDislike,
            active: message.feedback == model.MessageFeedback.disliked,
          ),
          const SizedBox(width: 2),
          _icon(scheme, Icons.refresh_rounded, 'Regenerate', onRegenerate),
        ],
      ),
    );
  }

  Widget _icon(ColorScheme scheme, IconData icon, String tooltip, VoidCallback onTap, {bool active = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: active ? scheme.primary : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
