import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/user_profile.dart';
import '../services/assistant_service.dart';
import '../services/storage_service.dart';
import 'saved_answers_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/workspace/presentation/workspace_screen.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/sync/data/sync_service.dart';
import '../features/sync/domain/sync_operation.dart';
import '../core/di/injection_container.dart' as di;
import '../core/constants/app_keys.dart'
    show kGeminiModels, kGroqModels, kOpenRouterModels;
import '../core/design_system/design_system.dart';
import '../widgets/markdown_message.dart';
import '../widgets/message_actions.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/welcome_animation.dart';

const String _welcomeMessage =
    'Salaam! I am Banataq, your AI assistant for school, business, writing, '
    'ideas, and everyday problem-solving. Ask me anything.';

class BanataqHome extends StatefulWidget {
  final String? initialPrompt;
  const BanataqHome({super.key, this.initialPrompt});

  @override
  State<BanataqHome> createState() => _BanataqHomeState();
}

class _BanataqHomeState extends State<BanataqHome> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _assistant = di.sl<AssistantService>();
  StorageService get _storage => di.sl<StorageService>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Conversation> _conversations = [];
  String? _currentId;
  List<ChatMessage> _messages = [];
  bool _thinking = false;
  bool _loadingStorage = true;
  String? _loadError;
  String? _persona;
  StreamSubscription<String>? _streamSub;
  int? _streamingMessageIndex;
  final List<PlatformFile> _pendingFiles = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onComposerChanged);
    _init();
  }

  void _onComposerChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasUserMessages => _messages.any((m) => m.fromUser);

  bool get _showWelcome =>
      !_hasUserMessages && !_thinking && _controller.text.isEmpty;

  Future<void> _init() async {
    await _assistant.loadConfig();
    final profile = await _storage.loadProfile(userId: _userId);
    _persona = profile?.persona.label;
    await _loadFromStorage();
    final prompt = widget.initialPrompt;
    if (prompt != null && prompt.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(prompt.trim()));
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.removeListener(_onComposerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _loadFromStorage() async {
    try {
      var conversations = await _storage.loadConversations(userId: _userId);
      if (conversations.isEmpty) {
        final defaultConv = Conversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          messages: [ChatMessage(fromUser: false, text: _welcomeMessage)],
          createdAt: DateTime.now(),
        );
        _conversations = [defaultConv];
        _currentId = defaultConv.id;
        _messages = List.from(defaultConv.messages);
        await _storage.saveConversations(_conversations, userId: _userId);
      } else {
        _sortConversations();
        _conversations = conversations;
        // Fresh chat on cold start after the app was swiped away.
        final fresh = Conversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          messages: [ChatMessage(fromUser: false, text: _welcomeMessage)],
          createdAt: DateTime.now(),
        );
        _conversations.insert(0, fresh);
        _currentId = fresh.id;
        _messages = List.from(fresh.messages);
      }
    } catch (_) {
      _loadError = 'Could not load conversations';
      _messages = [ChatMessage(fromUser: false, text: _welcomeMessage)];
    }
    if (mounted) setState(() => _loadingStorage = false);
  }

  String? get _userId {
    final authState = context.read<AuthBloc>().state;
    return authState.user?.uid;
  }

  String? get _displayName {
    final name = context.read<AuthBloc>().state.user?.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    // Use first name only: "Jay Chibuzor" -> "Jay"
    return name.split(' ').first;
  }

  SyncService get _syncService => di.sl<SyncService>();

  Future<void> _syncCurrentConversation() async {
    final userId = _userId;
    if (userId == null || _currentId == null) return;
    final index = _conversations.indexWhere((c) => c.id == _currentId);
    if (index < 0) return;
    await _syncService.syncConversation(
      userId: userId,
      conversationId: _currentId!,
      data: _conversations[index].toJson(),
      type: SyncOperationType.update,
    );
  }

  Future<void> _persist() async {
    if (_currentId == null) return;
    final index = _conversations.indexWhere((c) => c.id == _currentId);
    if (index < 0) return;
    _conversations[index].messages = List.from(_messages);
    _conversations[index].updatedAt = DateTime.now();
    final firstUser = _messages.firstWhere(
      (m) => m.fromUser,
      orElse: () => ChatMessage(fromUser: false, text: ''),
    );
    if (firstUser.text.isNotEmpty && _conversations[index].title.isEmpty) {
      _conversations[index].title = firstUser.text.length > 42
          ? '${firstUser.text.substring(0, 42)}...'
          : firstUser.text;
    }
    await _storage.saveConversations(_conversations, userId: _userId);
  }

  void _newConversation() async {
    _streamSub?.cancel();
    await _persist();
    final conv = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      messages: [ChatMessage(fromUser: false, text: _welcomeMessage)],
      createdAt: DateTime.now(),
    );
    setState(() {
      _conversations.insert(0, conv);
      _currentId = conv.id;
      _messages = List.from(conv.messages);
      _streamingMessageIndex = null;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
    await _persist();
    await _syncCurrentConversation();
  }

  void _selectConversation(String id) async {
    _streamSub?.cancel();
    await _persist();
    final conv = _conversations.firstWhere((c) => c.id == id);
    setState(() {
      _currentId = conv.id;
      _messages = List.from(conv.messages);
      _streamingMessageIndex = null;
    });
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _renameConversation(String id) {
    final conv = _conversations.firstWhere((c) => c.id == id);
    final ctrl = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Conversation name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final i = _conversations.indexWhere((c) => c.id == id);
                if (i >= 0) {
                  _conversations[i].title = name;
                  await _storage.saveConversations(
                    _conversations,
                    userId: _userId,
                  );
                  if (mounted) setState(() {});
                }
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  void _togglePin(String id) async {
    final i = _conversations.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final conv = _conversations[i];
    if (conv.pinned) {
      conv.pinned = false;
      conv.pinnedAt = null;
    } else {
      conv.pinned = true;
      conv.pinnedAt = DateTime.now();
    }
    _sortConversations();
    await _storage.saveConversations(_conversations, userId: _userId);
    if (mounted) setState(() {});
  }

  void _deleteConversation(String id) async {
    _streamSub?.cancel();
    final userId = _userId;
    _conversations.removeWhere((c) => c.id == id);
    if (userId != null) {
      await _syncService.syncConversation(
        userId: userId,
        conversationId: id,
        data: {},
        type: SyncOperationType.delete,
      );
    }
    if (_conversations.isEmpty) {
      final conv = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        messages: [ChatMessage(fromUser: false, text: _welcomeMessage)],
        createdAt: DateTime.now(),
      );
      _conversations = [conv];
      _currentId = conv.id;
      _messages = List.from(conv.messages);
    } else if (_currentId == id) {
      final conv = _conversations.first;
      _currentId = conv.id;
      _messages = List.from(conv.messages);
    }
    await _persist();
    if (mounted) setState(() => _streamingMessageIndex = null);
  }

  Future<void> _pickFiles() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      setState(() => _pendingFiles.addAll(res.files));
      // fire-and-forget upload to Firebase Storage for persistence
      unawaited(_uploadPending());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pick failed: $e')));
      }
    }
  }

  Future<void> _uploadPending() async {
    final uid = _userId;
    if (uid == null) return;
    for (final f in List<PlatformFile>.from(_pendingFiles)) {
      try {
        final path = f.path;
        if (path == null) continue;
        final ref = FirebaseStorage.instance.ref(
          'users/$uid/chats/${_currentId ?? 'pending'}/${f.name}',
        );
        await ref.putFile(File(path));
      } catch (_) {}
    }
  }

  Future<void> _send([String? value]) async {
    _streamSub?.cancel();
    var text = (value ?? _controller.text).trim();
    if (text.isEmpty && _pendingFiles.isEmpty) return;
    if (_thinking) return;
    if (_pendingFiles.isNotEmpty) {
      final names = _pendingFiles.map((f) => f.name).join(', ');
      text = text.isEmpty
          ? 'Attached files: $names'
          : 'Attached files: $names\n\n$text';
      _pendingFiles.clear();
    }
    _controller.clear();

    final userMsg = ChatMessage(fromUser: true, text: text);
    final aiMsg = ChatMessage(fromUser: false, text: '', isStreaming: true);

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _thinking = true;
      _streamingMessageIndex = _messages.length - 1;
    });
    _scrollToBottom();

    final history = _messages.length > 3
        ? _messages
              .sublist(0, _messages.length - 2)
              .where((m) => !m.isStreaming)
              .map(
                (m) => {
                  'role': m.fromUser ? 'user' : 'assistant',
                  'content': m.text,
                },
              )
              .toList()
        : null;

    try {
      final stream = _assistant.replyStream(
        text,
        persona: _persona,
        displayName: _displayName,
        history: history,
      );
      String accumulated = '';
      _streamSub = stream.listen(
        (chunk) {
          accumulated += chunk;
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            setState(
              () => _messages[_streamingMessageIndex!].text = accumulated,
            );
          }
          _scrollToBottom();
        },
        onDone: () async {
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            if (accumulated.trim().isEmpty) {
              accumulated =
                  'No response was received. Check your internet connection and try again.';
              _messages[_streamingMessageIndex!].text = accumulated;
            }
            setState(() {
              _messages[_streamingMessageIndex!].isStreaming = false;
              _thinking = false;
              _streamingMessageIndex = null;
            });
          }
          await _persist();
          await _syncCurrentConversation();
        },
        onError: (e) {
          debugPrint('Chat stream error: $e');
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            final idx = _streamingMessageIndex!;
            if (_messages[idx].text.isEmpty) {
              _messages[idx].text = _friendlyStreamError(e);
            }
            setState(() {
              _messages[idx].isStreaming = false;
              _thinking = false;
              _streamingMessageIndex = null;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Chat send error: $e');
      if (!mounted) return;
      final idx = _streamingMessageIndex;
      if (idx != null && idx < _messages.length) {
        setState(() {
          _messages[idx].text = _friendlyStreamError(e);
          _messages[idx].isStreaming = false;
          _thinking = false;
          _streamingMessageIndex = null;
        });
      }
    }
  }

  void _regenerate() async {
    if (!_assistant.canRegenerate || _streamingMessageIndex != null) return;

    int targetIdx = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].fromUser) {
        targetIdx = i;
        break;
      }
    }
    if (targetIdx < 0) return;

    setState(() {
      _messages[targetIdx].text = '';
      _messages[targetIdx].isStreaming = true;
      _thinking = true;
      _streamingMessageIndex = targetIdx;
    });

    try {
      final stream = _assistant.regenerateStream(
        persona: _persona,
        displayName: _displayName,
      );
      String accumulated = '';
      _streamSub = stream.listen(
        (chunk) {
          accumulated += chunk;
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            setState(
              () => _messages[_streamingMessageIndex!].text = accumulated,
            );
          }
          _scrollToBottom();
        },
        onDone: () async {
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            setState(() {
              _messages[_streamingMessageIndex!].isStreaming = false;
              _thinking = false;
              _streamingMessageIndex = null;
            });
          }
          await _persist();
          await _syncCurrentConversation();
        },
        onError: (e) {
          debugPrint('Chat regenerate error: $e');
          if (mounted &&
              _streamingMessageIndex != null &&
              _streamingMessageIndex! < _messages.length) {
            final idx = _streamingMessageIndex!;
            if (_messages[idx].text.isEmpty) {
              _messages[idx].text = _friendlyStreamError(e);
            }
            setState(() {
              _messages[idx].isStreaming = false;
              _thinking = false;
              _streamingMessageIndex = null;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Chat regenerate error: $e');
      if (!mounted) return;
      if (_streamingMessageIndex != null &&
          _streamingMessageIndex! < _messages.length) {
        setState(() {
          _messages[_streamingMessageIndex!].text = _friendlyStreamError(e);
          _messages[_streamingMessageIndex!].isStreaming = false;
          _thinking = false;
          _streamingMessageIndex = null;
        });
      }
    }
  }

  /// Turns provider exceptions into a short, readable bubble instead of the
  /// old generic "something went wrong" that hid the cause.
  String _friendlyStreamError(Object e) {
    final raw = e.toString();
    final match = RegExp(r'Exception: (.+)').firstMatch(raw);
    final message = match?.group(1) ?? raw;
    return 'Could not get a response.\n$message';
  }

  void _stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    if (mounted) {
      setState(() {
        _thinking = false;
        _streamingMessageIndex = null;
        if (_messages.isNotEmpty) {
          final last = _messages.last;
          if (!last.fromUser) last.isStreaming = false;
        }
      });
    }
    _persist();
  }

  Future<void> _clearAllHistory() async {
    _streamSub?.cancel();
    _conversations = [];
    final fresh = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      messages: [ChatMessage(fromUser: false, text: _welcomeMessage)],
      createdAt: DateTime.now(),
    );
    _conversations = [fresh];
    _currentId = fresh.id;
    _messages = List.from(fresh.messages);
    _streamingMessageIndex = null;
    _pendingFiles.clear();
    await _storage.saveConversations([], userId: _userId);
    await _storage.saveConversations(_conversations, userId: _userId);
    final uid = _userId;
    if (uid != null) {
      for (final c in List<Conversation>.from(_conversations)) {
        await _syncService.syncConversation(
          userId: uid,
          conversationId: c.id,
          data: c.toJson(),
          type: SyncOperationType.update,
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _showModelSwitcher() async {
    await _assistant.loadConfig();
    if (!mounted) return;
    await AppBottomSheet.show<bool>(
      context,
      title: 'Switch model',
      child: _ModelSwitcherSheet(
        assistant: _assistant,
        onChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _saveAnswer(ChatMessage message) async {
    final saved = await _storage.loadSavedAnswers(userId: _userId);
    saved.add(message);
    await _storage.saveSavedAnswers(saved, userId: _userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _setFeedback(ChatMessage message, MessageFeedback fb) {
    final i = _messages.indexOf(message);
    if (i < 0) return;
    final current = _messages[i].feedback;
    setState(() {
      _messages[i] = _messages[i].copyWith(
        feedback: current == fb ? null : fb,
        clearFeedback: current == fb,
      );
    });
    _persist();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loadingStorage) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 24 : 14),
              child: isWide
                  ? Row(
                      children: [
                        SizedBox(
                          width: 360,
                          child: _brandPanel(onPrompt: _send),
                        ),
                        const SizedBox(width: 18),
                        Expanded(child: _chatPanel()),
                      ],
                    )
                  : Column(
                      children: [
                        _mobileHeader(onPrompt: _send),
                        const SizedBox(height: 10),
                        Expanded(child: _chatPanel(showHeader: false)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Drawer(
      child: Container(
        color: scheme.surfaceContainerLow,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const _BanataqMark(size: 36),
                    const SizedBox(width: 10),
                    Text('Banataq', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _newConversation,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New chat'),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Expanded(
                child: _conversations.isEmpty
                    ? Center(
                        child: Text(
                          'No conversations yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final active = conv.id == _currentId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Material(
                              color: active
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _selectConversation(conv.id),
                                onLongPress: () =>
                                    _showConversationMenu(context, conv),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      if (conv.pinned) ...[
                                        Icon(
                                          Icons.push_pin_rounded,
                                          size: 14,
                                          color: const Color(0xFFD4AF5A),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          conv.title.isEmpty
                                              ? 'New chat'
                                              : conv.title,
                                          style: TextStyle(
                                            fontWeight: active
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (active)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Gmail + Settings side-by-side footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 2),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, auth) {
                    final email = auth.user?.email ?? '';
                    final name = auth.user?.displayName ?? 'User';
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'B';
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          tooltip: 'Settings',
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: const Text('Saved Answers'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedAnswersScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: const Text('Workspace'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Clear all history',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Clear all chats?'),
                      content: const Text(
                        'This will delete all conversations. Like GPT, this cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await _clearAllHistory();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showConversationMenu(BuildContext context, Conversation conv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _menuTile(Icons.edit_rounded, 'Rename', () {
                Navigator.pop(ctx);
                _renameConversation(conv.id);
              }),
              _menuTile(
                conv.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                conv.pinned ? 'Unpin' : 'Pin to top',
                () {
                  Navigator.pop(ctx);
                  _togglePin(conv.id);
                },
              ),
              _menuTile(Icons.delete_outline_rounded, 'Delete', () {
                Navigator.pop(ctx);
                _deleteConversation(conv.id);
              }, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      onTap: onTap,
    );
  }

  Widget _chatPanel({bool showHeader = true}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.50 : 0.55),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const _BanataqMark(size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Banataq',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Your AI study & work assistant',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _assistant.providerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () {
                            setState(() {
                              _loadingStorage = true;
                              _loadError = null;
                            });
                            _loadFromStorage();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _showWelcome
                ? _WelcomeView(onPrompt: _send)
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    itemCount:
                        _messages.length +
                        (_thinking && _streamingMessageIndex == null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (_thinking &&
                          _streamingMessageIndex == null &&
                          index == _messages.length) {
                        return const TypingIndicator();
                      }
                      if (index >= _messages.length) return const SizedBox();
                      final msg = _messages[index];
                      final isLastAi =
                          !msg.fromUser &&
                          index == _messages.length - 1 &&
                          !msg.isStreaming;
                      return Column(
                        crossAxisAlignment: msg.fromUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          _messageBubble(msg, theme),
                          if (!msg.fromUser &&
                              msg.text.isNotEmpty &&
                              !msg.isStreaming)
                            MessageActions(
                              message: msg,
                              onSave: () => _saveAnswer(msg),
                              onLike: () =>
                                  _setFeedback(msg, MessageFeedback.liked),
                              onDislike: () =>
                                  _setFeedback(msg, MessageFeedback.disliked),
                              onRegenerate: isLastAi ? _regenerate : () {},
                            ),
                          if (!msg.fromUser && msg.isStreaming)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Generating...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          if (_pendingFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _pendingFiles)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 160,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? scheme.surfaceContainerHigh
                                    : scheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: isDark ? 0.85 : 1.0,
                                  ),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(8, 8, 28, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _isImageFile(f)
                                        ? (f.path != null
                                              ? Image.file(
                                                  File(f.path!),
                                                  fit: BoxFit.cover,
                                                  width: 38,
                                                  height: 38,
                                                  // ignore: unnecessary_underscores
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(
                                                        Icons.image_outlined,
                                                        size: 18,
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                                )
                                              : Icon(
                                                  Icons.image_outlined,
                                                  size: 18,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ))
                                        : Icon(
                                            f.extension?.toLowerCase() == 'pdf'
                                                ? Icons.picture_as_pdf_outlined
                                                : Icons.description_outlined,
                                            size: 18,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          f.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            letterSpacing: -0.1,
                                            color: scheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _fileSizeLabel(f.size),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: scheme.onSurfaceVariant,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Material(
                                color: scheme.surfaceContainerHighest,
                                shape: const CircleBorder(),
                                elevation: 0,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () =>
                                      setState(() => _pendingFiles.remove(f)),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scheme.surfaceContainerHighest,
                                      border: Border.all(
                                        color: scheme.outlineVariant,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _Composer(
              controller: _controller,
              onSend: () => _send(),
              isStreaming: _thinking,
              onStop: _stopStreaming,
              onSwitchModel: _showModelSwitcher,
              onPickFiles: _pickFiles,
              hasPendingFiles: _pendingFiles.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageFile(PlatformFile f) {
    final ext = f.extension?.toLowerCase();
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp';
  }

  String _fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _messageBubble(ChatMessage msg, ThemeData theme) {
    final scheme = theme.colorScheme;
    // Assistant — premium workspace content, no enclosing bubble
    if (!msg.fromUser) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 12, 2),
            child: MarkdownMessage(text: msg.text),
          ),
        ),
      );
    }
    // User — compact confident pill, accent only for user
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(
              AppRadius.lg,
            ).copyWith(bottomRight: const Radius.circular(6)),
          ),
          child: SelectableText(
            msg.text,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandPanel({required ValueChanged<String> onPrompt}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BanataqMark(size: 60),
          const SizedBox(height: 24),
          Text(
            'Ask. Learn. Create.',
            style: theme.textTheme.displaySmall?.copyWith(
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personal AI study and work assistant — explain anything, summarize notes, draft writing, and manage your projects in one smart workspace.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _CapabilityGrid(onPrompt: onPrompt),
          const Spacer(),
          const _LocalFirstCard(),
        ],
      ),
    );
  }

  Widget _mobileHeader({required ValueChanged<String> onPrompt}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 10, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.50 : 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const _BanataqMark(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _showModelSwitcher,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Banataq',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      Text(
                        'Your AI study & work assistant',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _assistant.providerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt),
                  onPressed: () => onPrompt(prompt),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _quickPrompts = [
    'Summarize my note',
    'Explain a question',
    'Write a caption',
    'Solve this problem',
  ];
}

class _CapabilityGrid extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  const _CapabilityGrid({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Capability(
        icon: Icons.school_outlined,
        title: 'Study helper',
        prompt: 'Explain this exam question like I am a beginner.',
      ),
      _Capability(
        icon: Icons.edit_note_outlined,
        title: 'Writing',
        prompt: 'Write a short business announcement for WhatsApp.',
      ),
      _Capability(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Ideas',
        prompt: 'Give me five simple app ideas for Nigerian students.',
      ),
      _Capability(
        icon: Icons.storefront_outlined,
        title: 'Business',
        prompt: 'Help me describe my small business professionally.',
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => ActionChip(
              avatar: Icon(item.icon, size: 18),
              label: Text(item.title),
              onPressed: () => onPrompt(item.prompt),
            ),
          )
          .toList(),
    );
  }
}

class _LocalFirstCard extends StatelessWidget {
  const _LocalFirstCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by design',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Banataq runs locally on your device. Your questions and answers stay with you.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
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

class _WelcomeView extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  const _WelcomeView({required this.onPrompt});

  static const _actions = [
    _WelcomeAction('Explain something', 'Explain something to me clearly.'),
    _WelcomeAction('Help me write', 'Help me write something.'),
    _WelcomeAction('Work with a file', 'Help me work with a file.'),
    _WelcomeAction('Help me study', 'Help me study for an exam.'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WelcomeAnimation(size: 52),
              const SizedBox(height: 20),
              Text(
                'How can I help?',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ask a question, work through an idea,\nor give me something to do.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _actions
                    .map(
                      (a) => ActionChip(
                        label: Text(a.label),
                        onPressed: () => onPrompt(a.prompt),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeAction {
  final String label;
  final String prompt;
  const _WelcomeAction(this.label, this.prompt);
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onSwitchModel;
  final VoidCallback? onPickFiles;
  final bool isStreaming;
  final bool hasPendingFiles;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onStop,
    required this.onSwitchModel,
    this.onPickFiles,
    this.hasPendingFiles = false,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.trim().isNotEmpty || hasPendingFiles;
    final canSend = hasText && !isStreaming;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.85 : 1.0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach — native professional control
          if (onPickFiles != null)
            _ComposerIconButton(
              icon: Icons.attach_file_rounded,
              tooltip: 'Attach file',
              onPressed: onPickFiles!,
              scheme: scheme,
            ),
          // Model switcher — "+" keeps existing behavior, now subtle
          _ComposerIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Switch model',
            onPressed: onSwitchModel,
            scheme: scheme,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) =>
                  isStreaming ? onStop() : (canSend ? onSend() : null),
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface,
                letterSpacing: -0.1,
              ),
              decoration: InputDecoration(
                hintText: isStreaming
                    ? 'Banataq is replying…'
                    : 'Ask Banataq anything…',
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.62),
                  letterSpacing: -0.1,
                ),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
              cursorColor: scheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          // Send / Stop — accent only here
          _ComposerSendButton(
            isStreaming: isStreaming,
            canSend: canSend,
            onSend: onSend,
            onStop: onStop,
            scheme: scheme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorScheme scheme;
  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ComposerSendButton extends StatelessWidget {
  final bool isStreaming;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ColorScheme scheme;
  final bool isDark;
  const _ComposerSendButton({
    required this.isStreaming,
    required this.canSend,
    required this.onSend,
    required this.onStop,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isStreaming) {
      return Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onStop,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: scheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.stop_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final enabled = canSend;
    return Material(
      color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: enabled ? onSend : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: enabled ? Colors.transparent : scheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 18,
            color: enabled
                ? scheme.onPrimary
                : scheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _ModelSwitcherSheet extends StatefulWidget {
  final AssistantService assistant;
  final VoidCallback onChanged;
  const _ModelSwitcherSheet({required this.assistant, required this.onChanged});

  @override
  State<_ModelSwitcherSheet> createState() => _ModelSwitcherSheetState();
}

class _ModelSwitcherSheetState extends State<_ModelSwitcherSheet> {
  final _modelController = TextEditingController();
  final _urlController = TextEditingController();
  late AiProviderType _selected;
  bool _busy = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _selected = widget.assistant.providerType;
    _modelController.text = widget.assistant.ollamaModel;
    _urlController.text = widget.assistant.ollamaServerUrl;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _select(AiProviderType type) async {
    if (type == _selected || _busy) return;
    setState(() => _busy = true);
    if (type == AiProviderType.ollama) {
      await widget.assistant.setOllamaModel(_modelController.text.trim());
    }
    await widget.assistant.setProvider(type, '');
    if (!mounted) return;
    setState(() {
      _selected = type;
      _busy = false;
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${widget.assistant.providerName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveOllamaModel() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.assistant.setOllamaModel(_modelController.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ollama model updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveOllamaUrl() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.assistant.setOllamaUrl(_urlController.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ollama server updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _testResult = null;
    });
    final result = await widget.assistant.testOllamaConnection();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _testResult = result;
    });
  }

  Future<void> _saveGeminiModel(String model) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.assistant.setGeminiModel(model);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gemini model updated to $model'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final type in AiProviderType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _selected == type
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _select(type),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(_icon(type), color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(type),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _subtitle(type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selected == type)
                        Icon(
                          Icons.check_circle,
                          color: scheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_selected == AiProviderType.ollama) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Ollama server address',
                hintText: 'http://192.168.1.100:11434/v1',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: TextButton(
                  onPressed: _busy ? null : _saveOllamaUrl,
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Ollama model name',
                hintText: 'qwen3:1.7b',
                prefixIcon: const Icon(Icons.memory_rounded),
                suffixIcon: TextButton(
                  onPressed: _busy ? null : _saveOllamaModel,
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _testConnection,
              icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
              label: const Text('Test connection'),
            ),
          ),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _testResult!,
                style: TextStyle(
                  fontSize: 13,
                  color: _testResult!.startsWith('Connected')
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
        if (_selected == AiProviderType.gemini) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DropdownButtonFormField<String>(
              initialValue: widget.assistant.geminiModel,
              decoration: const InputDecoration(
                labelText: 'Gemini model',
                prefixIcon: Icon(Icons.auto_awesome_rounded),
              ),
              items: kGeminiModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _saveGeminiModel(v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Ready instantly — just pick a model. Works on the free tier, no setup.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (_selected == AiProviderType.groq)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DropdownButtonFormField<String>(
              initialValue: widget.assistant.groqModel,
              decoration: const InputDecoration(
                labelText: 'Groq model',
                prefixIcon: Icon(Icons.bolt_rounded),
              ),
              items: kGroqModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _saveProviderModel(v, 'Groq');
              },
            ),
          ),
        if (_selected == AiProviderType.openRouter) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DropdownButtonFormField<String>(
              initialValue: widget.assistant.openRouterModel,
              decoration: const InputDecoration(
                labelText: 'OpenRouter model',
                prefixIcon: Icon(Icons.hub_rounded),
              ),
              items: kOpenRouterModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _saveProviderModel(v, 'OpenRouter');
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveProviderModel(String model, String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_selected == AiProviderType.groq) {
      await widget.assistant.setGroqModel(model);
    } else {
      await widget.assistant.setOpenRouterModel(model);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label model updated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _icon(AiProviderType type) => switch (type) {
    AiProviderType.local => Icons.computer,
    AiProviderType.ollama => Icons.memory,
    AiProviderType.openai => Icons.psychology,
    AiProviderType.gemini => Icons.auto_awesome,
    AiProviderType.groq => Icons.bolt,
    AiProviderType.openRouter => Icons.hub,
  };

  String _label(AiProviderType type) => switch (type) {
    AiProviderType.local => 'Local (offline)',
    AiProviderType.ollama => 'Ollama (local model)',
    AiProviderType.openai => 'OpenAI',
    AiProviderType.gemini => 'Google Gemini',
    AiProviderType.groq => 'Groq (ultra fast)',
    AiProviderType.openRouter => 'OpenRouter',
  };

  String _subtitle(AiProviderType type) => switch (type) {
    AiProviderType.local => 'Built-in starter brain. Works offline.',
    AiProviderType.ollama => 'Qwen3 on your computer. No API key needed.',
    AiProviderType.openai => 'Requires an API key.',
    AiProviderType.gemini => 'Free tier ready out of the box.',
    AiProviderType.groq => 'Fastest responses, free out of the box.',
    AiProviderType.openRouter => 'Free open models, ready to go.',
  };
}

class _BanataqMark extends StatelessWidget {
  final double size;
  const _BanataqMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2C477), Color(0xFFD4AF5A), Color(0xFFC89B3C)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: const Color(0xFFC89B3C).withValues(alpha: 0.40),
        ),
      ),
      child: Center(
        child: Text(
          'Bq',
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF3A2E05),
          ),
        ),
      ),
    );
  }
}

class _Capability {
  final IconData icon;
  final String title;
  final String prompt;
  const _Capability({
    required this.icon,
    required this.title,
    required this.prompt,
  });
}
