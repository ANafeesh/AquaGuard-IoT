/// Firestore Document: devices/{deviceId}
class Device {
  final String id;
  final String name;
  final String ownerUid;
  final DateTime lastSeenAt;
  final int? batteryLevel;
  final int? signalStrength; // dBm or percentage
  final String? firmwareVersion;

  const Device({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.lastSeenAt,
    this.batteryLevel,
    this.signalStrength,
    this.firmwareVersion,
  });

  /// A device is considered online if seen in the last 10 minutes
  bool get isOnline {
    final diff = DateTime.now().difference(lastSeenAt);
    return diff.inMinutes < 10;
  }

  String get lastSeenFormatted {
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Device copyWith({
    String? id,
    String? name,
    String? ownerUid,
    DateTime? lastSeenAt,
    int? batteryLevel,
    int? signalStrength,
    String? firmwareVersion,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid ?? this.ownerUid,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerUid': ownerUid,
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'batteryLevel': batteryLevel,
      'signalStrength': signalStrength,
      'firmwareVersion': firmwareVersion,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? 'dev_01',
      name: json['name'] as String? ?? 'ESP32 Sensor Node',
      ownerUid: json['ownerUid'] as String? ?? 'system',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
      signalStrength: (json['signalStrength'] as num?)?.toInt(),
      firmwareVersion: json['firmwareVersion'] as String? ?? 'v1.0.4-iot',
    );
  }
}
