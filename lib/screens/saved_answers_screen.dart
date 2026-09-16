import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../core/di/injection_container.dart' as di;
import '../features/auth/presentation/bloc/auth_bloc.dart';

class SavedAnswersScreen extends StatefulWidget {
  const SavedAnswersScreen({super.key});

  @override
  State<SavedAnswersScreen> createState() => _SavedAnswersScreenState();
}

class _SavedAnswersScreenState extends State<SavedAnswersScreen> {
  StorageService get _storage => di.sl<StorageService>();
  List<ChatMessage> _answers = [];
  bool _loading = true;

  String? get _userId {
    final authState = context.read<AuthBloc>().state;
    return authState.user?.uid;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final answers = await _storage.loadSavedAnswers(userId: _userId);
    if (!mounted) return;
    setState(() {
      _answers = answers;
      _loading = false;
    });
  }

  Future<void> _delete(int index) async {
    final removed = _answers.removeAt(index);
    await _storage.saveSavedAnswers(_answers, userId: _userId);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Answer removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            _answers.insert(index, removed);
            await _storage.saveSavedAnswers(_answers, userId: _userId);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Answers'), centerTitle: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _answers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_outline_rounded,
                      size: 64,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved answers yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Long-press any Banataq reply to save it here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _answers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final answer = _answers[index];
                return Dismissible(
                  key: ValueKey('saved_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  onDismissed: (_) => _delete(index),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: answer.fromUser
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          answer.fromUser ? 'You' : 'Banataq',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: answer.fromUser
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(answer.text),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
