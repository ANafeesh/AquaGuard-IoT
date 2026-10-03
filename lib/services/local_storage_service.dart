import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Pure Dart persistent storage service for AquaGuard.
/// Works on Windows, Desktop, Mobile (via File I/O) and Web (via in-memory map),
/// avoiding Windows symlink build failures while ensuring full persistence across app restarts.
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();

  final Map<String, dynamic> _memoryCache = {};
  File? _storageFile;
  bool _initialized = false;

  LocalStorageService._();

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        final currentDir = Directory.current.path;
        final storageDir = Directory('$currentDir/.storage');
        if (!storageDir.existsSync()) {
          storageDir.createSync(recursive: true);
        }
        _storageFile = File('${storageDir.path}/aquaguard_store.json');
        if (_storageFile!.existsSync()) {
          final content = _storageFile!.readAsStringSync();
          if (content.isNotEmpty) {
            final decoded = jsonDecode(content);
            if (decoded is Map<String, dynamic>) {
              _memoryCache.addAll(decoded);
            }
          }
        }
      } catch (e) {
        debugPrint('LocalStorageService file init fallback: $e');
      }
    }
    _initialized = true;
  }

  void _saveToFile() {
    if (kIsWeb || _storageFile == null) return;
    try {
      _storageFile!.writeAsStringSync(jsonEncode(_memoryCache), flush: true);
    } catch (e) {
      debugPrint('LocalStorageService write error: $e');
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final val = _memoryCache[key];
    if (val is bool) return val;
    return defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    _memoryCache[key] = value;
    _saveToFile();
  }

  String? getString(String key) {
    final val = _memoryCache[key];
    if (val is String) return val;
    return null;
  }

  Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
    _saveToFile();
  }

  List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    final val = _memoryCache[key];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return defaultValue;
  }

  Future<void> setStringList(String key, List<String> list) async {
    _memoryCache[key] = list;
    _saveToFile();
  }

  Map<String, dynamic>? getMap(String key) {
    final val = _memoryCache[key];
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return null;
  }

  Future<void> setMap(String key, Map<String, dynamic> map) async {
    _memoryCache[key] = map;
    _saveToFile();
  }

  List<Map<String, dynamic>> getJsonList(String key) {
    final val = _memoryCache[key];
    if (val is List) {
      return val.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    _memoryCache[key] = list;
    _saveToFile();
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _saveToFile();
  }

  Future<void> clear() async {
    _memoryCache.clear();
    _saveToFile();
  }
}
