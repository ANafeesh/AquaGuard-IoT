import 'water_source.dart';

/// Firestore Document: alerts/{alertId}
class AlertItem {
  final String id;
  final String sourceId;
  final String measurementId;
  final String parameter;
  final String message;
  final double? value;
  final DateTime createdAt;
  final bool acknowledged;

  // UI convenience helpers
  final String waterSourceName;
  final WaterQualityStatus severity;
  final String investigationAdvice;

  const AlertItem({
    required this.id,
    required this.sourceId,
    required this.measurementId,
    required this.parameter,
    this.message = 'Unusual water-quality measurement detected at this location.',
    this.value,
    required this.createdAt,
    this.acknowledged = false,
    this.waterSourceName = 'Monitored Source',
    this.severity = WaterQualityStatus.unusual,
    this.investigationAdvice = 'Unusual measurement detected. Further investigation may be required.',
  });

  // Legacy compatibility getters
  String get title => 'Unusual $parameter Reading';
  String get description => message;
  bool get isRead => acknowledged;
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  AlertItem copyWith({
    String? id,
    String? sourceId,
    String? measurementId,
    String? parameter,
    String? message,
    double? value,
    DateTime? createdAt,
    bool? acknowledged,
    String? waterSourceName,
    WaterQualityStatus? severity,
    String? investigationAdvice,
  }) {
    return AlertItem(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      measurementId: measurementId ?? this.measurementId,
      parameter: parameter ?? this.parameter,
      message: message ?? this.message,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      acknowledged: acknowledged ?? this.acknowledged,
      waterSourceName: waterSourceName ?? this.waterSourceName,
      severity: severity ?? this.severity,
      investigationAdvice: investigationAdvice ?? this.investigationAdvice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'measurementId': measurementId,
      'parameter': parameter,
      'message': message,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'acknowledged': acknowledged,
      'waterSourceName': waterSourceName,
      'severity': severity.name,
      'investigationAdvice': investigationAdvice,
    };
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String? ?? 'alt_${DateTime.now().millisecondsSinceEpoch}',
      sourceId: json['sourceId'] as String? ?? '',
      measurementId: json['measurementId'] as String? ?? '',
      parameter: json['parameter'] as String? ?? 'Indicator',
      message: json['message'] as String? ??
          'Unusual water-quality measurement detected at this location.',
      value: (json['value'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      acknowledged: (json['acknowledged'] as bool?) ?? (json['isRead'] as bool?) ?? false,
      waterSourceName: json['waterSourceName'] as String? ?? 'Water Source',
      severity: WaterQualityStatus.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => WaterQualityStatus.unusual,
      ),
      investigationAdvice: json['investigationAdvice'] as String? ??
          'Unusual measurement detected. Further investigation may be required.',
    );
  }
}
