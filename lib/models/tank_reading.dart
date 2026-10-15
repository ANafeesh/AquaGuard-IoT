import '../core/config/parameter_thresholds.dart';
import 'water_source.dart';

/// Firestore Document: home_tanks/{tankId}/readings/{readingId}
/// Private telemetry reading for a registered home water tank.
class TankReading {
  final String id;
  final String tankId;
  final String ownerUid;
  final String? deviceId;
  final double ph;
  final double tdsEc;
  final double turbidity;
  final double temperature;
  final DateTime timestamp;
  final String source; // 'device' | 'manual'
  final WaterQualityStatus status;
  final String? notes;

  const TankReading({
    required this.id,
    required this.tankId,
    required this.ownerUid,
    this.deviceId,
    required this.ph,
    required this.tdsEc,
    required this.turbidity,
    required this.temperature,
    required this.timestamp,
    this.source = 'device',
    this.status = WaterQualityStatus.withinTypicalRange,
    this.notes,
  });

  bool get isDevice => source.toLowerCase() == 'device';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tankId': tankId,
      'ownerUid': ownerUid,
      'deviceId': deviceId,
      'ph': ph,
      'tdsEc': tdsEc,
      'turbidity': turbidity,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'status': status.name,
      'notes': notes,
    };
  }

  factory TankReading.fromJson(Map<String, dynamic> json) {
    final ph = (json['ph'] as num?)?.toDouble() ?? 7.0;
    final tds = (json['tdsEc'] as num?)?.toDouble() ?? 250.0;
    final turb = (json['turbidity'] as num?)?.toDouble() ?? 1.5;
    final temp = (json['temperature'] as num?)?.toDouble() ?? 26.0;

    final statusStr = json['status'] as String?;
    WaterQualityStatus status;
    if (statusStr != null) {
      status = WaterQualityStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => WaterQualityStatus.withinTypicalRange,
      );
    } else {
      final isTypical = ParameterThresholds.isPhTypical(ph) &&
          ParameterThresholds.isTdsTypical(tds) &&
          ParameterThresholds.isTurbidityTypical(turb) &&
          ParameterThresholds.isTempTypical(temp);
      status = isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual;
    }

    return TankReading(
      id: json['id'] as String? ?? 'tr_${DateTime.now().millisecondsSinceEpoch}',
      tankId: json['tankId'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      ph: ph,
      tdsEc: tds,
      turbidity: turb,
      temperature: temp,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'device',
      status: status,
      notes: json['notes'] as String?,
    );
  }
}
