import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../repositories/water_source_repository.dart';
import '../repositories/reading_repository.dart';
import '../repositories/alert_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock/mock_water_source_repository.dart';
import '../repositories/mock/mock_reading_repository.dart';
import '../repositories/mock/mock_alert_repository.dart';
import '../repositories/mock/mock_report_repository.dart';
import '../repositories/mock/mock_auth_repository.dart';
import '../repositories/firebase/firebase_water_source_repository.dart';
import '../repositories/firebase/firebase_reading_repository.dart';
import '../repositories/firebase/firebase_alert_repository.dart';
import '../repositories/firebase/firebase_report_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';

/// Provider for WaterSourceRepository
final waterSourceRepositoryProvider = Provider<WaterSourceRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockWaterSourceRepository();
  }
  return FirebaseWaterSourceRepository();
});

/// Provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockReadingRepository();
  }
  return FirebaseReadingRepository();
});

/// Provider for AlertRepository
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockAlertRepository();
  }
  return FirebaseAlertRepository();
});

/// Provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockReportRepository();
  }
  return FirebaseReportRepository();
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockAuthRepository();
  }
  return FirebaseAuthRepository();
});
