import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../domain/entities/app_settings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/assistant_service.dart';
import '../../../../core/constants/app_keys.dart'
    show kGeminiModels, kGroqModels, kOpenRouterModels;
import '../../../../core/di/injection_container.dart' as di;

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SettingsBloc>()..add(const LoadSettings()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          final exportData = state.exportData;
          if (exportData != null) {
            _showExport(context, exportData);
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state.status == SettingsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = state.settings;

            return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader(title: 'Appearance'),
              _ThemeSelector(settings: settings),
              const SizedBox(height: 6),
              _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                trailing: DropdownButton<String>(
                  value: settings.language,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ha', child: Text('Hausa')),
                    DropdownMenuItem(value: 'yo', child: Text('Yoruba')),
                    DropdownMenuItem(value: 'ig', child: Text('Igbo')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      context.read<SettingsBloc>().add(UpdateLanguage(v));
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'AI Provider'),
              const _ProviderSelector(),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Memory'),
              _SwitchTile(
                icon: Icons.memory,
                title: 'Memory',
                subtitle: 'Banataq remembers your preferences across conversations',
                value: settings.memoryEnabled,
                onChanged: (v) => context.read<SettingsBloc>().add(UpdateMemoryEnabled(v)),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Privacy'),
              _SwitchTile(
                icon: Icons.analytics_outlined,
                title: 'Usage Analytics',
                subtitle: 'Help improve Banataq by sharing anonymous usage data',
                value: settings.analyticsEnabled,
                onChanged: (v) => context.read<SettingsBloc>().add(UpdateAnalyticsEnabled(v)),
              ),
              _SwitchTile(
                icon: Icons.history,
                title: 'Save Chat History',
                subtitle: 'Keep your conversations accessible across devices',
                value: settings.saveChatHistory,
                onChanged: (v) => context.read<SettingsBloc>().add(UpdateSaveChatHistory(v)),
              ),
              _SwitchTile(
                icon: Icons.model_training,
                title: 'Allow Training',
                subtitle: 'Allow your conversations to be used to improve the AI model',
                value: settings.allowTraining,
                onChanged: (v) => context.read<SettingsBloc>().add(UpdateAllowTraining(v)),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Data'),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export Data'),
                subtitle: const Text('Download all your data'),
                onTap: () {
                  final uid = context.read<AuthBloc>().state.user?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign in to export your data')),
                    );
                    return;
                  }
                  context.read<SettingsBloc>().add(ExportDataRequested(uid));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently delete your account and all data'),
                onTap: () => _showDeleteConfirmation(context),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Account'),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  context.read<AuthBloc>().add(const SignOutRequested());
                },
              ),
            ],
          );
          },
        ),
      ),
    );
  }

  void _showExport(BuildContext context, String exportData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your exported data'),
        content: SingleChildScrollView(
          child: SelectableText(exportData, style: const TextStyle(fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const DeleteAccountRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppSettings settings;
  const _ThemeSelector({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ThemeMode.values.map((mode) {
        final active = settings.theme == mode;
        final label = mode.name[0].toUpperCase() + mode.name.substring(1);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label),
              selected: active,
              onSelected: (_) {
                context.read<SettingsBloc>().add(UpdateTheme(mode));
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProviderSelector extends StatefulWidget {
  const _ProviderSelector();

  @override
  State<_ProviderSelector> createState() => _ProviderSelectorState();
}

class _ProviderSelectorState extends State<_ProviderSelector> {
  late final AssistantService _assistant = di.sl<AssistantService>();
  late AiProviderType _selected;
  final _keyController = TextEditingController();
  final _urlController = TextEditingController();
  final _modelController = TextEditingController();
  final _geminiModelController = TextEditingController();
  bool _keyVisible = false;
  bool _saving = false;
  bool _loaded = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _assistant.loadConfig();
    final config = await StorageService().loadAiConfig();
    final key = config['apiKey'] as String? ?? '';
    if (!mounted) return;
    setState(() {
      _selected = _assistant.providerType;
      _urlController.text = _assistant.ollamaServerUrl;
      _modelController.text = _assistant.ollamaModel;
      _geminiModelController.text = _assistant.geminiModel;
      _keyController.text = key;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    _geminiModelController.dispose();
    super.dispose();
  }

  Future<void> _selectProvider(AiProviderType type) async {
    setState(() {
      _selected = type;
      _saving = true;
    });
    if (type == AiProviderType.ollama) {
      await _assistant.setOllamaUrl(_urlController.text.trim());
      await _assistant.setOllamaModel(_modelController.text.trim());
    }
    await _assistant.setProvider(type, _keyController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI provider switched to ${_assistant.providerName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveOllamaUrl() async {
    setState(() => _saving = true);
    await _assistant.setOllamaUrl(_urlController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ollama server updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveOllamaModel() async {
    setState(() => _saving = true);
    await _assistant.setOllamaModel(_modelController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ollama model updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveApiKey() async {
    setState(() => _saving = true);
    await _assistant.setProvider(_selected, _keyController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveGeminiModel() async {
    setState(() => _saving = true);
    await _assistant.setGeminiModel(_geminiModelController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gemini model updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveGroqModel(String model) async {
    setState(() => _saving = true);
    await _assistant.setGroqModel(model);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Groq model updated to $model'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveOpenRouterModel(String model) async {
    setState(() => _saving = true);
    await _assistant.setOpenRouterModel(model);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OpenRouter model updated to $model'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _saving = true;
      _testResult = null;
    });
    await _assistant.setProvider(_selected, _keyController.text.trim());
    final result = await _assistant.testOllamaConnection();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        ...AiProviderType.values.map((type) {
          final active = _loaded && _selected == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: active ? scheme.primaryContainer : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _loaded && !_saving ? () => _selectProvider(type) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_providerIcon(type), color: scheme.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _providerLabel(type),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _providerDescription(type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (active)
                        Icon(Icons.check_circle, color: scheme.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_loaded && _selected == AiProviderType.ollama)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:11434/v1',
                labelText: 'Ollama server address',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: TextButton(
                  onPressed: _saving ? null : _saveOllamaUrl,
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        if (_loaded && _selected == AiProviderType.ollama)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _modelController,
              decoration: InputDecoration(
                hintText: 'qwen3:1.7b',
                labelText: 'Ollama model name',
                prefixIcon: const Icon(Icons.memory_rounded),
                suffixIcon: TextButton(
                  onPressed: _saving ? null : _saveOllamaModel,
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        if (_loaded && _selected == AiProviderType.openai)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _keyController,
              obscureText: !_keyVisible,
              decoration: InputDecoration(
                hintText: 'sk-...',
                labelText: 'API key',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _keyVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _keyVisible = !_keyVisible),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _saveApiKey,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_loaded && _selected == AiProviderType.gemini)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _assistant.geminiModel,
                    decoration: const InputDecoration(
                      labelText: 'Gemini model',
                      prefixIcon: Icon(Icons.auto_awesome_rounded),
                    ),
                    items: kGeminiModels
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _geminiModelController.text = v;
                      _saveGeminiModel();
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_loaded && _selected == AiProviderType.groq)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _assistant.groqModel,
              decoration: const InputDecoration(
                labelText: 'Groq model',
                prefixIcon: Icon(Icons.bolt_rounded),
              ),
              items: kGroqModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                _saveGroqModel(v);
              },
            ),
          ),
        if (_loaded && _selected == AiProviderType.openRouter)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _assistant.openRouterModel,
              decoration: const InputDecoration(
                labelText: 'OpenRouter model',
                prefixIcon: Icon(Icons.hub_rounded),
              ),
              items: kOpenRouterModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                _saveOpenRouterModel(v);
              },
            ),
          ),
        if (_loaded &&
            (_selected == AiProviderType.gemini ||
                _selected == AiProviderType.groq ||
                _selected == AiProviderType.openRouter))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Ready out of the box — just pick a model, no setup needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_loaded && _selected == AiProviderType.openai)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _testConnection,
              icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
              label: const Text('Test connection'),
            ),
          ),
        if (_loaded && _selected == AiProviderType.ollama)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _testConnection,
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
        if (_loaded && _selected == AiProviderType.ollama)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Points to the computer running Ollama on your network, or 127.0.0.1 when a model runs on this phone. No API key needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_loaded && _selected == AiProviderType.local)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Works fully offline with a built-in starter brain. Limited canned responses.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  IconData _providerIcon(AiProviderType type) => switch (type) {
        AiProviderType.local => Icons.computer,
        AiProviderType.ollama => Icons.memory,
        AiProviderType.openai => Icons.psychology,
        AiProviderType.gemini => Icons.auto_awesome,
        AiProviderType.groq => Icons.bolt,
        AiProviderType.openRouter => Icons.hub,
      };

  String _providerLabel(AiProviderType type) => switch (type) {
        AiProviderType.local => 'Local (offline)',
        AiProviderType.ollama => 'Ollama (local model)',
        AiProviderType.openai => 'OpenAI',
        AiProviderType.gemini => 'Google Gemini',
        AiProviderType.groq => 'Groq (ultra fast)',
        AiProviderType.openRouter => 'OpenRouter',
      };

  String _providerDescription(AiProviderType type) => switch (type) {
        AiProviderType.local => 'Built-in starter brain. Works offline.',
        AiProviderType.ollama => 'Qwen3 on your computer. No API key. Fastest on your network.',
        AiProviderType.openai => 'Requires an API key. Most capable.',
        AiProviderType.gemini => 'Ready out of the box with the built-in key.',
        AiProviderType.groq => 'Ready out of the box. Fastest responses, free tier.',
        AiProviderType.openRouter => 'Ready out of the box. Rotates free open models.',
      };
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
    );
  }
}
