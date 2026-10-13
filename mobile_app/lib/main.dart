import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
import 'providers/user_preferences_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
