import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../repositories/water_source_repository.dart';
import '../repositories/reading_repository.dart';
import '../repositories/alert_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/home_tank_repository.dart';
import '../repositories/mock/mock_water_source_repository.dart';
import '../repositories/mock/mock_reading_repository.dart';
import '../repositories/mock/mock_alert_repository.dart';
import '../repositories/mock/mock_report_repository.dart';
import '../repositories/mock/mock_auth_repository.dart';
import '../repositories/mock/mock_device_repository.dart';
import '../repositories/mock/mock_home_tank_repository.dart';
import '../repositories/firebase/firebase_water_source_repository.dart';
import '../repositories/firebase/firebase_reading_repository.dart';
import '../repositories/firebase/firebase_alert_repository.dart';
import '../repositories/firebase/firebase_report_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_device_repository.dart';
import '../repositories/firebase/firebase_home_tank_repository.dart';

/// Provider for WaterSourceRepository
final waterSourceRepositoryProvider = Provider<WaterSourceRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockWaterSourceRepository();
  }
  return FirebaseWaterSourceRepository();
});

/// Provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockReadingRepository();
  }
  return FirebaseReadingRepository();
});

/// Provider for AlertRepository
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockAlertRepository();
  }
  return FirebaseAlertRepository();
});

/// Provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockReportRepository();
  }
  return FirebaseReportRepository();
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockAuthRepository();
  }
  return FirebaseAuthRepository();
});

/// Provider for DeviceRepository
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockDeviceRepository();
  }
  return FirebaseDeviceRepository();
});

/// Provider for HomeTankRepository
final homeTankRepositoryProvider = Provider<HomeTankRepository>((ref) {
  if (AppConfig.useMockData || !AppConfig.isFirebaseInitialized) {
    return MockHomeTankRepository();
  }
  return FirebaseHomeTankRepository();
});

