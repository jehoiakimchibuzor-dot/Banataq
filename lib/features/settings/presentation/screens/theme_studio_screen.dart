import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/tokens/accent_theme.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class ThemeStudioScreen extends StatelessWidget {
  const ThemeStudioScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('Theme'), centerTitle: false),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Make BANATAQ yours.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              // Appearance
              Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)), ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)), ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto))],
                selected: {settings.theme},
                onSelectionChanged: (v) => context.read<SettingsBloc>().add(UpdateTheme(v.first)),
              ),
              const SizedBox(height: 20),
              Text('Accent', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...AccentTheme.values.map((a) {
                final t = kAccentTokens[a]!;
                final sel = a == settings.accentTheme;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => context.read<SettingsBloc>().add(UpdateAccentTheme(a)),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? t.primary : Theme.of(context).colorScheme.outlineVariant, width: sel ? 2 : 1),
                      ),
                      child: Row(children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [t.gradientStart, t.gradientEnd]))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 6), if (sel) Icon(Icons.check_circle, size: 16, color: t.primary)]),
                          const SizedBox(height: 2),
                          Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: LinearGradient(colors: [t.primary.withValues(alpha: 0.9), t.bright]))),
                        ])),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text('Intensity', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<AccentIntensity>(
                segments: const [ButtonSegment(value: AccentIntensity.soft, label: Text('Soft')), ButtonSegment(value: AccentIntensity.balanced, label: Text('Balanced')), ButtonSegment(value: AccentIntensity.vibrant, label: Text('Vibrant'))],
                selected: {settings.accentIntensity},
                onSelectionChanged: (v) => context.read<SettingsBloc>().add(UpdateAccentIntensity(v.first)),
              ),
            ],
          ),
        );
      },
    );
  }
}
