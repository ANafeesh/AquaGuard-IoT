import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
import 'providers/user_preferences_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();

  // Initialize Firebase with graceful fallback to mock mode if unconfigured or offline
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppConfig.isFirebaseInitialized = true;
      debugPrint('[AquaGuard] Firebase connected successfully.');
    } else {
      debugPrint(
        '[AquaGuard] Firebase credentials not configured. Running with offline mock mode.',
      );
    }
  } catch (e) {
    debugPrint(
      '[AquaGuard] Firebase initialization error: $e. Falling back to offline mock mode.',
    );
    AppConfig.isFirebaseInitialized = false;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: AquaGuardApp(),
    ),
  );
}

class AquaGuardApp extends ConsumerWidget {
  const AquaGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);

    return MaterialApp(
      title: 'AquaGuard - Smart Water Monitoring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        '/main': (context) => const MainNavigationScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
