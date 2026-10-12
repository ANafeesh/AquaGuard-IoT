import '../core/config/parameter_thresholds.dart';

/// Water source classification types
enum WaterSourceType {
  river,
  lake,
  well,
  reservoir,
  stream,
  other,
}

extension WaterSourceTypeExtension on WaterSourceType {
  String get value {
    switch (this) {
      case WaterSourceType.river:
        return 'river';
      case WaterSourceType.lake:
        return 'lake';
      case WaterSourceType.well:
        return 'well';
      case WaterSourceType.reservoir:
        return 'reservoir';
      case WaterSourceType.stream:
        return 'stream';
      case WaterSourceType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case WaterSourceType.river:
        return 'River';
      case WaterSourceType.lake:
        return 'Lake';
      case WaterSourceType.well:
        return 'Groundwater Well';
      case WaterSourceType.reservoir:
        return 'Reservoir';
      case WaterSourceType.stream:
        return 'Stream';
      case WaterSourceType.other:
        return 'Other Source';
    }
  }

  static WaterSourceType fromString(String? val) {
    if (val == null) return WaterSourceType.other;
    return WaterSourceType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => WaterSourceType.other,
    );
  }
}

/// Strictly neutral environmental indicator baseline status
enum WaterQualityStatus {
  withinTypicalRange, // Green/Teal - Within expected baseline parameters
  unusual,            // Amber/Coral - Unusual change detected
  noRecentData,       // Slate - Sensor node offline or telemetry missing (> 2 hours without reading)
}

extension WaterQualityStatusExtension on WaterQualityStatus {
  String get label {
    switch (this) {
      case WaterQualityStatus.withinTypicalRange:
        return 'Within expected range';
      case WaterQualityStatus.unusual:
        return 'Unusual change detected';
      case WaterQualityStatus.noRecentData:
        return 'No recent data';
    }
  }

  String get shortLabel {
    switch (this) {
      case WaterQualityStatus.withinTypicalRange:
        return 'Normal';
      case WaterQualityStatus.unusual:
        return 'Unusual';
      case WaterQualityStatus.noRecentData:
        return 'No Data';
    }
  }
}

/// Firestore Document: sources/{sourceId}
class WaterSource {
  final String id;
  final String name;
  final WaterSourceType type;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastReadingAt;
  
  // Latest reading snapshot cached on the source for fast dashboard & map rendering
  final double? ph;
  final double? tdsEc;
  final double? turbidity;
  final double? temperature;
  final WaterQualityStatus status;
  final String? description;

  const WaterSource({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.createdAt,
    this.lastReadingAt,
    this.ph,
    this.tdsEc,
    this.turbidity,
    this.temperature,
    this.status = WaterQualityStatus.withinTypicalRange,
    this.description,
  });

  // Legacy compatibility getters for existing widgets
  int get tds => (tdsEc ?? 0).toInt();
  String get locationArea => '${type.displayName} Catchment';
  String get coordinates => '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
  String get lastUpdated {
    if (lastReadingAt == null) return 'No recent data';
    final diff = DateTime.now().difference(lastReadingAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  WaterSource copyWith({
    String? id,
    String? name,
    WaterSourceType? type,
    double? latitude,
    double? longitude,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastReadingAt,
    double? ph,
    double? tdsEc,
    double? turbidity,
    double? temperature,
    WaterQualityStatus? status,
    String? description,
  }) {
    return WaterSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
      ph: ph ?? this.ph,
      tdsEc: tdsEc ?? this.tdsEc,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastReadingAt': lastReadingAt?.toIso8601String(),
      'ph': ph,
      'tdsEc': tdsEc,
      'turbidity': turbidity,
      'temperature': temperature,
      'status': status.name,
      'description': description,
    };
  }

  factory WaterSource.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final lastReading = json['lastReadingAt'] != null
        ? DateTime.tryParse(json['lastReadingAt'].toString())
        : null;

    // Compute status if missing or outdated (> 2 hours without telemetry)
    WaterQualityStatus status;
    if (lastReading != null && DateTime.now().difference(lastReading).inHours > 2) {
      status = WaterQualityStatus.noRecentData;
    } else if (statusStr != null) {
      status = WaterQualityStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => WaterQualityStatus.withinTypicalRange,
      );
    } else {
      // Evaluate from values if available
      final ph = (json['ph'] as num?)?.toDouble();
      final tds = (json['tdsEc'] as num?)?.toDouble() ?? (json['tds'] as num?)?.toDouble();
      final turb = (json['turbidity'] as num?)?.toDouble();
      final temp = (json['temperature'] as num?)?.toDouble();

      final isTypical = (ph == null || ParameterThresholds.isPhTypical(ph)) &&
          (tds == null || ParameterThresholds.isTdsTypical(tds)) &&
          (turb == null || ParameterThresholds.isTurbidityTypical(turb)) &&
          (temp == null || ParameterThresholds.isTempTypical(temp));
      status = isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual;
    }

    return WaterSource(
      id: json['id'] as String? ?? 'src_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Water Source',
      type: WaterSourceTypeExtension.fromString(json['type'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdBy: json['createdBy'] as String? ?? 'system',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastReadingAt: lastReading,
      ph: (json['ph'] as num?)?.toDouble(),
      tdsEc: (json['tdsEc'] as num?)?.toDouble() ?? (json['tds'] as num?)?.toDouble(),
      turbidity: (json['turbidity'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      status: status,
      description: json['description'] as String?,
    );
  }
}
