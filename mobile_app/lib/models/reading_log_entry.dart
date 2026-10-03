import 'water_source.dart';

class ReadingLogEntry {
  final String id;
  final String waterSourceId;
  final String waterSourceName;
  final DateTime timestamp;
  final double ph;
  final int tds;
  final double turbidity;
  final double temperature;
  final WaterQualityStatus status;
  final String notes;

  const ReadingLogEntry({
    required this.id,
    required this.waterSourceId,
    required this.waterSourceName,
    required this.timestamp,
    required this.ph,
    required this.tds,
    required this.turbidity,
    required this.temperature,
    required this.status,
    this.notes = 'Automated telemetry snapshot recorded.',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waterSourceId': waterSourceId,
      'waterSourceName': waterSourceName,
      'timestamp': timestamp.toIso8601String(),
      'ph': ph,
      'tds': tds,
      'turbidity': turbidity,
      'temperature': temperature,
      'status': status.name,
      'notes': notes,
    };
  }

  factory ReadingLogEntry.fromJson(Map<String, dynamic> json) {
    return ReadingLogEntry(
      id: json['id'] as String,
      waterSourceId: json['waterSourceId'] as String,
      waterSourceName: json['waterSourceName'] as String? ?? 'Water Source',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      ph: (json['ph'] as num).toDouble(),
      tds: (json['tds'] as num).toInt(),
      turbidity: (json['turbidity'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      status: WaterQualityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WaterQualityStatus.withinTypicalRange,
      ),
      notes: json['notes'] as String? ?? 'Automated telemetry snapshot recorded.',
    );
  }
}
