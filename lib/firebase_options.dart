// File configured for AquaGuard IoT Smart Water Monitoring.
// Project: aquaguard-iot-b8ce2

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
  static const String projectId = 'aquaguard-iot-b8ce2';
  static const String apiKey = 'AIzaSyCfVyFmFrvELir5w9_2-_RZwZ-m8t-XMXE';
  static const String appId = '1:113372996651:web:bd9a0cf19e47b8ebbab66e';
  static const String messagingSenderId = '113372996651';
  static const String storageBucket = 'aquaguard-iot-b8ce2.firebasestorage.app';
  static const String authDomain = 'aquaguard-iot-b8ce2.firebaseapp.com';
  static const String measurementId = 'G-ZTN8CTEJ2L';

  /// Helper to check if actual credentials have been configured
  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      !apiKey.contains('Placeholder');

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
    authDomain: authDomain,
    storageBucket: storageBucket,
    measurementId: measurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:113372996651:android:bd9a0cf19e47b8ebbab66e',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:113372996651:ios:bd9a0cf19e47b8ebbab66e',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.example.aquaguard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:113372996651:ios:bd9a0cf19e47b8ebbab66e',
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
    authDomain: authDomain,
    storageBucket: storageBucket,
    measurementId: measurementId,
  );
}
