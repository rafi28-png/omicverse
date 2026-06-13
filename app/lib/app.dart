// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/colors.dart';

final routerProvider = Provider<GoRouter>((ref) => createRouter());

class OmicVerseApp extends ConsumerStatefulWidget {
  final bool supabaseConfigured;
  const OmicVerseApp({super.key, required this.supabaseConfigured});

  @override
  ConsumerState<OmicVerseApp> createState() => _OmicVerseAppState();
}

class _OmicVerseAppState extends ConsumerState<OmicVerseApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'OmicVerse',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          primary: kNeonTeal,
          surface: kSurface,
        ),
      ),
    );
  }
}
