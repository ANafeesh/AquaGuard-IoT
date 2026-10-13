// File generated for AquaGuard IoT Smart Water Monitoring.
// Replace the placeholder values below with your Firebase Project configuration,
// or run `flutterfire configure` to automatically overwrite with official values.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  /// Replace these with your actual Firebase Project configuration values,
  /// or run `flutterfire configure` from the terminal.
  static const String projectId = 'aquaguard-iot';
  static const String apiKey = 'AIzaSyPlaceholderAquaGuardKey1234567890';
  static const String appId = '1:123456789012:web:placeholderAquaGuardAppId';
  static const String messagingSenderId = '123456789012';
  static const String storageBucket = 'aquaguard-iot.firebasestorage.app';

  /// Helper to check if actual credentials (not placeholder) have been provided
  static bool get isConfigured {
    // If apiKey is still the placeholder, we treat it as unconfigured
    // and gracefully fall back to mock repositories without throwing exceptions.
    return apiKey.isNotEmpty &&
        !apiKey.contains('Placeholder') &&
        projectId.isNotEmpty &&
        !projectId.contains('placeholder');
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: storageBucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:123456789012:android:placeholderAquaGuardAndroid',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:123456789012:ios:placeholderAquaGuardIos',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.example.aquaguard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:123456789012:ios:placeholderAquaGuardIos',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.example.aquaguard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: storageBucket,
  );
}
