import 'water_source.dart';
import 'measurement.dart';

/// Representation of a community or device observation in the feed
class CommunityObservation {
  final String id;
  final String? userId;
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
  final bool isDeviceSource;
  final bool isPendingSync;
  final DateTime timestamp;

  const CommunityObservation({
    required this.id,
    this.userId,
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
    this.isDeviceSource = false,
    this.isPendingSync = false,
    required this.timestamp,
  });

  CommunityObservation copyWith({
    String? id,
    String? userId,
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
    bool? isDeviceSource,
    bool? isPendingSync,
    DateTime? timestamp,
  }) {
    return CommunityObservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      isDeviceSource: isDeviceSource ?? this.isDeviceSource,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory CommunityObservation.fromMeasurement(Measurement m, {String sourceName = 'Monitored Source'}) {
    final diff = DateTime.now().difference(m.timestamp);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }

    final isDevice = m.isDevice;
    return CommunityObservation(
      id: m.id,
      userId: isDevice ? m.deviceId : null,
      waterSourceName: sourceName,
      locationArea: '${m.latitude.toStringAsFixed(3)}°, ${m.longitude.toStringAsFixed(3)}°',
      userName: isDevice ? 'ESP32 Node (${m.deviceId ?? "Auto"})' : m.submittedBy,
      userAvatar: isDevice ? 'IOT' : (m.submittedBy.isNotEmpty ? m.submittedBy.substring(0, 1).toUpperCase() : 'CO'),
      timeAgo: timeAgo,
      notes: m.notes ?? (isDevice ? 'Automated telemetry stream' : 'Manual community field observation'),
      ph: m.ph,
      tds: m.tdsEc.toInt(),
      turbidity: m.turbidity,
      temperature: m.temperature,
      status: WaterQualityStatus.withinTypicalRange,
      hasPhoto: false,
      helpfulCount: 0,
      isDeviceSource: isDevice,
      isPendingSync: m.isPendingSync,
      timestamp: m.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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
      'isDeviceSource': isDeviceSource,
      'isPendingSync': isPendingSync,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CommunityObservation.fromJson(Map<String, dynamic> json) {
    return CommunityObservation(
      id: json['id'] as String? ?? 'obs_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String?,
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
      isDeviceSource: json['isDeviceSource'] as bool? ?? false,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
