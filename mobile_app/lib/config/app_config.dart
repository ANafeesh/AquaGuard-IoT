/// Global application configuration and environment flags.
class AppConfig {
  /// When true, MockRepository implementations are injected.
  /// When false, FirebaseRepository implementations are injected.
  /// UI components only talk to repository interfaces via Riverpod.
  static const bool useMockData = true;

  /// Application identifier & version info
  static const String appName = 'AquaGuard';
  static const String appVersion = '1.0.0';
  static const String prototypeNotice = 
      'UI/UX Prototype Mode: Realistic mock data used for demonstration. No physical IoT hardware or Firebase backend is connected.';
}
