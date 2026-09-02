import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../widgets/typing_indicator.dart';
import '../../intelligence/application/intelligence_engine.dart';
import '../data/repositories/workspace_repository.dart';
import '../domain/models/workspace_session.dart';
import '../domain/models/workspace_session_detail.dart';
import '../utils/time_ago.dart';
import '../widgets/sessions/session_message_bubble.dart';
import 'workspace_session_controller.dart';

/// Full working session: generated summary, action items, key facts, linked
/// files, the conversation itself and a "Continue working" composer. Designed
/// to feel like a workspace artifact, not a chat thread.
class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.repository,
    required this.sessionId,
    this.controller,
    this.engine,
  });

  final WorkspaceRepository repository;
  final String sessionId;

  /// Inject a controller (tests) or leave null to build one.
  final WorkspaceSessionController? controller;

  /// Optional brain-backed stack bridged into the session conversation.
  final IntelligenceEngine? engine;

  static const routeName = '/workspace/session';

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final WorkspaceSessionController _controller;
  late final bool _ownsController;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _composer = TextEditingController();
  final Set<int> _checkedActions = {};
  bool _composerAutofocus = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        WorkspaceSessionController(
          repository: widget.repository,
          sessionId: widget.sessionId,
          engine: widget.engine,
        );
    _controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToBottom);
    if (_ownsController) _controller.dispose();
    _scroll.dispose();
    _composer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final detail = _controller.detail;
          final session = detail.session;
          return Column(
            children: [
              AppTopBar(
                onBack: () => Navigator.of(context).maybePop(),
                title: session.title,
                subtitle: _metaLine(session),
                actions: [
                  AppIconButton(
                    icon: session.pinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    onPressed: _controller.togglePinned,
                    tooltip: session.pinned ? 'Unpin chat' : 'Pin chat',
                    isSelected: session.pinned,
                  ),
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    onPressed: _rename,
                    tooltip: 'Rename chat',
                  ),
                  AppIconButton(
                    icon: Icons.more_horiz_rounded,
                    onPressed: () => _showMore(session),
                    tooltip: 'Chat actions',
                  ),
                ],
              ),
              AppDivider(hairline: true),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: _buildItems(detail),
                ),
              ),
              _composerBar(session),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildItems(WorkspaceSessionDetail detail) {
    final spacing = 16.0;
    final items = <Widget>[];

    if (detail.aiSummary != null) {
      items.add(
        _SummaryCard(summary: detail.aiSummary!, onContinue: _focusComposer),
      );
      items.add(SizedBox(height: spacing));
    }

    if (detail.actionItems.isNotEmpty) {
      items.add(
        _ActionItemsCard(
          items: detail.actionItems,
          checked: _checkedActions,
          onCheck: _checkAction,
        ),
      );
      items.add(SizedBox(height: spacing));
    }

    if (detail.keyFacts.isNotEmpty) {
      items.add(_KeyFactsCard(facts: detail.keyFacts));
      items.add(SizedBox(height: spacing));
    }

    if (detail.linkedFiles.isNotEmpty) {
      items.add(_SectionLabel(label: 'Linked files'));
      items.add(SizedBox(height: 8));
      for (final file in detail.linkedFiles) {
        items.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: FileCard(
              name: file.name,
              type: file.type,
              meta: file.meta,
              summarized: file.summarized,
              onTap: () => _openFile(file.name),
            ),
          ),
        );
      }
    }

    final messages = detail.messages;
    if (messages.isNotEmpty) {
      items.add(SizedBox(height: spacing - 4));
      items.add(_SectionLabel(label: 'Conversation'));
      items.add(SizedBox(height: 12));
      for (var i = 0; i < messages.length; i++) {
        final message = messages[i];
        final isLastAi = message.fromAi && i == messages.length - 1;
        items.add(
          SessionMessageBubble(
            message: message,
            showRegenerate: isLastAi,
            onRegenerate: _controller.regenerateReply,
          ),
        );
        items.add(const SizedBox(height: 12));
      }
    }

    if (_controller.isSending) {
      items.add(const TypingIndicator());
      items.add(const SizedBox(height: 12));
    }

    return items;
  }

  Widget _composerBar(WorkspaceSession session) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: AppPromptField(
            key: ValueKey('composer-$_composerAutofocus'),
            controller: _composer,
            autofocus: _composerAutofocus,
            hint: 'Continue working on this chat...',
            sending: _controller.isSending,
            onSend: (text) => _controller.sendMessage(text),
          ),
        ),
      ),
    );
  }

  String _metaLine(WorkspaceSession session) {
    final parts = <String>[
      session.status.label,
      timeAgo(session.updatedAt),
      if (session.durationLabel != null) session.durationLabel!,
      if (session.messageCount > 0) '${session.messageCount} messages',
    ];
    return parts.join(' · ');
  }

  void _focusComposer() {
    setState(() => _composerAutofocus = true);
  }

  void _checkAction(int index) {
    setState(() => _checkedActions.add(index));
    _controller.checkActionItem(index);
  }

  void _openFile(String name) {
    AppSnackbar.show(context, 'Opening "$name" is coming in the next build.');
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _controller.detail.session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename chat'),
        content: AppTextField(
          controller: controller,
          autofocus: true,
          label: 'Chat title',
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || !mounted) return;
    _controller.rename(newTitle);
  }

  Future<void> _showMore(WorkspaceSession session) async {
    final action = await AppBottomSheet.show<_MoreAction>(
      context,
      title: 'Chat actions',
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              session.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            title: Text(session.archived ? 'Restore chat' : 'Archive chat'),
            onTap: () => Navigator.of(context).pop(_MoreAction.archive),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Chat info'),
            onTap: () => Navigator.of(context).pop(_MoreAction.info),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete chat',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.of(context).pop(_MoreAction.delete),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case _MoreAction.archive:
        _controller.toggleArchived();
      case _MoreAction.info:
        _showInfo(session);
      case _MoreAction.delete:
        await _confirmDelete();
    }
  }

  Future<void> _showInfo(WorkspaceSession session) async {
    await AppBottomSheet.show(
      context,
      title: 'Chat info',
      child: Column(
        children: [
          _InfoRow(label: 'Status', value: session.status.label),
          _InfoRow(label: 'Purpose', value: session.purpose ?? '—'),
          _InfoRow(
            label: 'Created',
            value: session.createdAt == null
                ? '—'
                : '${session.createdAt!.day}/${session.createdAt!.month}/${session.createdAt!.year}',
          ),
          _InfoRow(label: 'Last updated', value: timeAgo(session.updatedAt)),
          _InfoRow(label: 'Duration', value: session.durationLabel ?? '—'),
          _InfoRow(label: 'Messages', value: '${session.messageCount}'),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete chat?',
      message:
          '"${_controller.detail.session.title}" and its conversation will be '
          'removed from this workspace. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && mounted) {
      _controller.deleteSession();
      Navigator.of(context).maybePop();
    }
  }
}

enum _MoreAction { archive, info, delete }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.onContinue});

  final String summary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiBadge(label: 'Summary'),
              const Spacer(),
              TextButton(
                onPressed: onContinue,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Continue working',
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _ActionItemsCard extends StatelessWidget {
  const _ActionItemsCard({
    required this.items,
    required this.checked,
    required this.onCheck,
  });

  final List<String> items;
  final Set<int> checked;
  final ValueChanged<int> onCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AiBadge(label: 'Action items'),
              SizedBox(width: 8),
              Icon(Icons.fact_check_rounded, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCheckbox(
                    value: checked.contains(i),
                    onChanged: checked.contains(i) ? null : (v) => onCheck(i),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        items[i],
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: checked.contains(i)
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration: checked.contains(i)
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyFactsCard extends StatelessWidget {
  const _KeyFactsCard({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key facts',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fact in facts)
                AppChip(
                  label: fact,
                  icon: Icons.lightbulb_outline_rounded,
                  selected: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
