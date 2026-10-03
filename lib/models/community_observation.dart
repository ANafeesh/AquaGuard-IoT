import 'water_source.dart';

class CommunityObservation {
  final String id;
  final String waterSourceName;
  final String locationArea;
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String notes;
  final double? ph;
  final int? tds;
  final double? turbidity;
  final double? temperature;
  final WaterQualityStatus status;
  final bool hasPhoto;
  final int helpfulCount;

  const CommunityObservation({
    required this.id,
    required this.waterSourceName,
    required this.locationArea,
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.notes,
    this.ph,
    this.tds,
    this.turbidity,
    this.temperature,
    required this.status,
    this.hasPhoto = false,
    this.helpfulCount = 0,
  });

  CommunityObservation copyWith({
    String? id,
    String? waterSourceName,
    String? locationArea,
    String? userName,
    String? userAvatar,
    String? timeAgo,
    String? notes,
    double? ph,
    int? tds,
    double? turbidity,
    double? temperature,
    WaterQualityStatus? status,
    bool? hasPhoto,
    int? helpfulCount,
  }) {
    return CommunityObservation(
      id: id ?? this.id,
      waterSourceName: waterSourceName ?? this.waterSourceName,
      locationArea: locationArea ?? this.locationArea,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      notes: notes ?? this.notes,
      ph: ph ?? this.ph,
      tds: tds ?? this.tds,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waterSourceName': waterSourceName,
      'locationArea': locationArea,
      'userName': userName,
      'userAvatar': userAvatar,
      'timeAgo': timeAgo,
      'notes': notes,
      'ph': ph,
      'tds': tds,
      'turbidity': turbidity,
      'temperature': temperature,
      'status': status.name,
      'hasPhoto': hasPhoto,
      'helpfulCount': helpfulCount,
    };
  }

  factory CommunityObservation.fromJson(Map<String, dynamic> json) {
    return CommunityObservation(
      id: json['id'] as String,
      waterSourceName: json['waterSourceName'] as String? ?? 'Water Source',
      locationArea: json['locationArea'] as String? ?? 'Field Location',
      userName: json['userName'] as String? ?? 'AquaGuard User',
      userAvatar: json['userAvatar'] as String? ?? 'AG',
      timeAgo: json['timeAgo'] as String? ?? 'Recently',
      notes: json['notes'] as String? ?? '',
      ph: (json['ph'] as num?)?.toDouble(),
      tds: (json['tds'] as num?)?.toInt(),
      turbidity: (json['turbidity'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      status: WaterQualityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WaterQualityStatus.withinTypicalRange,
      ),
      hasPhoto: json['hasPhoto'] as bool? ?? false,
      helpfulCount: (json['helpfulCount'] as num?)?.toInt() ?? 0,
    );
  }
}
