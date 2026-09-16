import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/design_system/theme/app_theme_data.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/accent_mapper.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/profile/domain/usecases/initialize_profile.dart';
import 'models/onboarding_preferences.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/first_run_screen.dart';
import 'screens/personalization/personalization_screen.dart';
import 'features/workspace/presentation/workspace_screen.dart';
import 'widgets/brand_splash_screen.dart';
import 'services/storage_service.dart';

// Set to false before release so onboarding shows only once per install.
const bool kOnboardingEveryLoginForTesting = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.initDependencies();
  runApp(const BanataqApp());
}

final class BanataqApp extends StatelessWidget {
  const BanataqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()..add(const AuthCheckRequested())),
        BlocProvider<SettingsBloc>(create: (_) => di.sl<SettingsBloc>()..add(const LoadSettings())),
        BlocProvider<ProfileBloc>(create: (_) => di.sl<ProfileBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final s = settingsState.settings;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Banataq',
            theme: AppThemeData.fromScheme(schemeFor(s.accentTheme, Brightness.light, s.accentIntensity), Brightness.light),
            darkTheme: AppThemeData.fromScheme(schemeFor(s.accentTheme, Brightness.dark, s.accentIntensity), Brightness.dark),
            themeMode: s.theme,
            routes: {
              WorkspaceScreen.routeName: (_) => const WorkspaceScreen(),
            },
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

final class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _minSplashElapsed = false;
  Timer? _minSplashTimer;
  bool? _onboardingDone;
  bool? _personalizationDone;
  bool? _firstRunDone;
  String? _pendingPrompt;
  bool _showOnboardingForTesting = true;
  bool _showPersonalization = false;

  @override
  void initState() {
    super.initState();
    // Premium splash — B + BANATAQ drop must be seen
    _minSplashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
    _loadFlags();
    _listenToAuthChanges();
  }

  Future<void> _loadFlags() async {
    final s = di.sl<StorageService>();
    final o = await s.isOnboardingComplete();
    final p = await s.isPersonalizationComplete();
    final f = await s.isFirstRunComplete();
    if (mounted) setState(() { _onboardingDone = o; _personalizationDone = p; _firstRunDone = f; });
  }

  @override
  void dispose() {
    _minSplashTimer?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    final authBloc = context.read<AuthBloc>();
    authBloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated && state.user != null) {
        _ensureProfile(state.user!);
      } else if (state.status == AuthStatus.unauthenticated) {
        if (kOnboardingEveryLoginForTesting) {
          if (mounted) setState(() { _showOnboardingForTesting = true; _showPersonalization = false; });
        }
        // The Settings/profile screens are pushed on top of the home route.
        // When the user signs out or deletes the account from there, the root
        // swaps to the login screen but those pushed routes would otherwise
        // stay in the stack, hiding it. Pop back to the first route.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    });
  }

  Future<void> _ensureProfile(AuthUser authUser) async {
    final profileBloc = context.read<ProfileBloc>();
    final initializeProfile = di.sl<InitializeProfile>();

    await initializeProfile(
      uid: authUser.uid,
      email: authUser.email ?? '',
      displayName: authUser.displayName ?? 'User',
      photoUrl: authUser.photoUrl,
    );

    profileBloc.add(LoadProfile(authUser.uid));
  }

  void _onOnboardingDoneForTesting() {
    setState(() { _showOnboardingForTesting = false; _onboardingDone = true; });
  }

  void _onPersonalizationDone() {
    setState(() { _showPersonalization = false; _personalizationDone = true; });
  }

  Future<void> _onFirstRunStart(String prompt) async {
    await di.sl<StorageService>().setFirstRunComplete(value: true);
    if (!mounted) return;
    setState(() { _firstRunDone = true; _pendingPrompt = prompt; });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final status = state.status;
        Widget child;
        if (status == AuthStatus.unknown || status == AuthStatus.loading || !_minSplashElapsed || _onboardingDone == null || _personalizationDone == null || _firstRunDone == null) {
          child = const BrandSplashScreen();
        } else if (kOnboardingEveryLoginForTesting && status == AuthStatus.unauthenticated && _showOnboardingForTesting) {
          child = OnboardingScreen(key: const ValueKey('onboarding-testing'), storage: di.sl<StorageService>(), onComplete: _onOnboardingDoneForTesting);
        } else if (!_onboardingDone!) {
          child = OnboardingScreen(key: const ValueKey('onboarding-once'), storage: di.sl<StorageService>(), onComplete: () => setState(() => _onboardingDone = true));
        } else if (status == AuthStatus.unauthenticated) {
          child = const LoginScreen();
        } else if (status == AuthStatus.authenticated && (_showPersonalization || !_personalizationDone!)) {
          child = PersonalizationScreen(key: const ValueKey('personalization'), storage: di.sl<StorageService>(), onComplete: _onPersonalizationDone, onSkip: _onPersonalizationDone);
        } else if (status == AuthStatus.authenticated && !_firstRunDone!) {
          child = FutureBuilder<OnboardingPreferences?>(
            future: di.sl<StorageService>().loadOnboardingPreferences(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const BrandSplashScreen();
              final prefs = snap.data ?? const OnboardingPreferences();
              final user = state.user;
              return FirstRunScreen(
                key: const ValueKey('first-run'),
                preferences: prefs,
                displayName: user?.displayName ?? 'there',
                photoUrl: user?.photoUrl,
                onStartChat: _onFirstRunStart,
              );
            },
          );
        } else {
          final prompt = _pendingPrompt;
          if (prompt != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _pendingPrompt = null);
            });
          }
          child = switch (status) {
            AuthStatus.authenticated => AppShell(key: ValueKey('shell-${prompt ?? 'no-prompt'}'), initialPrompt: prompt),
            _ => const LoginScreen(),
          };
        }
        return AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: child);
      },
    );
  }
}
