// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: BingoApp()));
}

class BingoApp extends ConsumerWidget {
  const BingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    return MaterialApp(
      title: 'Bingo',
      debugShowCheckedModeBanner: false,
      theme: BingoTheme.light,
      darkTheme: BingoTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  _Phase _phase = _Phase.splash;

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.splash:
        return SplashScreen(
          onComplete: () => setState(() => _phase = _Phase.onboarding),
        );

      case _Phase.onboarding:
        // Watch the FutureProvider — reads from SharedPreferences on disk
        final hasSeen = ref.watch(hasSeenOnboardingProvider);

        return hasSeen.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const AppShell(), // fail-safe: skip onboarding
          data: (seen) {
            if (seen) return const AppShell();

            return OnboardingScreen(
              onComplete: () async {
                await markOnboardingSeen(); // writes true to SharedPreferences
                setState(() => _phase = _Phase.main);
              },
            );
          },
        );

      case _Phase.main:
        return const AppShell();
    }
  }
}

enum _Phase { splash, onboarding, main }