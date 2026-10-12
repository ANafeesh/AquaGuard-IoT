import '../core/config/parameter_thresholds.dart';
import 'water_source.dart';

enum ParameterType {
  ph,
  tds,
  turbidity,
  temperature,
}

/// Firestore Document: measurements/{measurementId}
class Measurement {
  final String id;
  final String sourceId;
  final String? deviceId;
  final double ph;
  final double tdsEc;
  final double turbidity;
  final double temperature;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String submittedBy;
  final String source; // "device" | "community"
  final DateTime? syncedAt;
  final String? notes;
  final bool isPendingSync;

  const Measurement({
    required this.id,
    required this.sourceId,
    this.deviceId,
    required this.ph,
    required this.tdsEc,
    required this.turbidity,
    required this.temperature,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.submittedBy,
    required this.source,
    this.syncedAt,
    this.notes,
    this.isPendingSync = false,
  });

  bool get isDevice => source.toLowerCase() == 'device';
  bool get isCommunity => source.toLowerCase() == 'community';

  Measurement copyWith({
    String? id,
    String? sourceId,
    String? deviceId,
    double? ph,
    double? tdsEc,
    double? turbidity,
    double? temperature,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? submittedBy,
    String? source,
    DateTime? syncedAt,
    String? notes,
    bool? isPendingSync,
  }) {
    return Measurement(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      deviceId: deviceId ?? this.deviceId,
      ph: ph ?? this.ph,
      tdsEc: tdsEc ?? this.tdsEc,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      submittedBy: submittedBy ?? this.submittedBy,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
      notes: notes ?? this.notes,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'deviceId': deviceId,
      'ph': ph,
      'tdsEc': tdsEc,
      'turbidity': turbidity,
      'temperature': temperature,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'submittedBy': submittedBy,
      'source': source,
      'syncedAt': syncedAt?.toIso8601String(),
      'notes': notes,
      'isPendingSync': isPendingSync,
    };
  }

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String? ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
      sourceId: json['sourceId'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
      tdsEc: (json['tdsEc'] as num?)?.toDouble() ?? (json['tds'] as num?)?.toDouble() ?? 250.0,
      turbidity: (json['turbidity'] as num?)?.toDouble() ?? 2.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 25.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      submittedBy: json['submittedBy'] as String? ?? 'unknown',
      source: json['source'] as String? ?? 'device',
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'].toString())
          : null,
      notes: json['notes'] as String?,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }
}

/// Helper model for individual parameter cards in UI
class ParameterReading {
  final ParameterType type;
  final String name;
  final String shortName;
  final double value;
  final String unit;
  final WaterQualityStatus status;
  final String statusText;
  final double normalMin;
  final double normalMax;

  const ParameterReading({
    required this.type,
    required this.name,
    required this.shortName,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusText,
    required this.normalMin,
    required this.normalMax,
  });

  factory ParameterReading.fromType({
    required ParameterType type,
    required double value,
    WaterQualityStatus? status,
  }) {
    switch (type) {
      case ParameterType.ph:
        final isTypical = ParameterThresholds.isPhTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.phLabel,
          shortName: ParameterThresholds.phShortLabel,
          value: value,
          unit: ParameterThresholds.phUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.phMin,
          normalMax: ParameterThresholds.phMax,
        );
      case ParameterType.tds:
        final isTypical = ParameterThresholds.isTdsTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.tdsLabel,
          shortName: ParameterThresholds.tdsShortLabel,
          value: value,
          unit: ParameterThresholds.tdsUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.tdsMin,
          normalMax: ParameterThresholds.tdsMax,
        );
      case ParameterType.turbidity:
        final isTypical = ParameterThresholds.isTurbidityTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.turbidityLabel,
          shortName: ParameterThresholds.turbidityShortLabel,
          value: value,
          unit: ParameterThresholds.turbidityUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.turbidityMin,
          normalMax: ParameterThresholds.turbidityMax,
        );
      case ParameterType.temperature:
        final isTypical = ParameterThresholds.isTempTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.tempLabel,
          shortName: ParameterThresholds.tempShortLabel,
          value: value,
          unit: ParameterThresholds.tempUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.tempMin,
          normalMax: ParameterThresholds.tempMax,
        );
    }
  }
}

class HistoricalPoint {
  final String timeLabel;
  final double value;
  final DateTime? dateTime;

  const HistoricalPoint(this.timeLabel, this.value, [this.dateTime]);
}
