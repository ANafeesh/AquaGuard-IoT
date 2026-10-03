import 'water_source.dart';

class AlertItem {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final WaterQualityStatus severity;
  final String waterSourceName;
  final bool isToday;
  final bool isRead;
  final String investigationAdvice;

  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.severity,
    required this.waterSourceName,
    required this.isToday,
    this.isRead = false,
    this.investigationAdvice = 'Unusual measurement detected. Further investigation may be required.',
  });

  AlertItem copyWith({
    String? id,
    String? title,
    String? description,
    String? timeAgo,
    WaterQualityStatus? severity,
    String? waterSourceName,
    bool? isToday,
    bool? isRead,
    String? investigationAdvice,
  }) {
    return AlertItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeAgo: timeAgo ?? this.timeAgo,
      severity: severity ?? this.severity,
      waterSourceName: waterSourceName ?? this.waterSourceName,
      isToday: isToday ?? this.isToday,
      isRead: isRead ?? this.isRead,
      investigationAdvice: investigationAdvice ?? this.investigationAdvice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeAgo': timeAgo,
      'severity': severity.name,
      'waterSourceName': waterSourceName,
      'isToday': isToday,
      'isRead': isRead,
      'investigationAdvice': investigationAdvice,
    };
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timeAgo: json['timeAgo'] as String? ?? 'Recently',
      severity: WaterQualityStatus.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => WaterQualityStatus.withinTypicalRange,
      ),
      waterSourceName: json['waterSourceName'] as String? ?? 'Water Source',
      isToday: json['isToday'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      investigationAdvice: json['investigationAdvice'] as String? ??
          'Unusual measurement detected. Further investigation may be required.',
    );
  }
}
