import '../core/config/parameter_thresholds.dart';
import 'water_source.dart';

/// Supported types of residential/home water tanks
enum HomeTankType {
  rooftop,
  underground,
  rainwater,
  indoor,
  other,
}

extension HomeTankTypeExtension on HomeTankType {
  String get value {
    switch (this) {
      case HomeTankType.rooftop:
        return 'rooftop';
      case HomeTankType.underground:
        return 'underground';
      case HomeTankType.rainwater:
        return 'rainwater';
      case HomeTankType.indoor:
        return 'indoor';
      case HomeTankType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case HomeTankType.rooftop:
        return 'Rooftop / Overhead Tank';
      case HomeTankType.underground:
        return 'Underground Sump / Cistern';
      case HomeTankType.rainwater:
        return 'Rainwater Harvesting Tank';
      case HomeTankType.indoor:
        return 'Indoor Storage Tank';
      case HomeTankType.other:
        return 'Other Water Tank';
    }
  }

  static HomeTankType fromString(String? val) {
    if (val == null) return HomeTankType.rooftop;
    return HomeTankType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => HomeTankType.rooftop,
    );
  }
}

/// Installation location captured for a private home water tank
class HomeTankInstallationLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String locationMethod; // 'gps' | 'map' | 'manual'
  final bool isConfirmed;

  const HomeTankInstallationLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.locationMethod = 'gps',
    this.isConfirmed = true,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'locationMethod': locationMethod,
      'isConfirmed': isConfirmed,
    };
  }

  factory HomeTankInstallationLocation.fromJson(Map<String, dynamic> json) {
    return HomeTankInstallationLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 79.8612,
      address: json['address'] as String? ?? 'Home Location',
      city: json['city'] as String?,
      locationMethod: json['locationMethod'] as String? ?? 'gps',
      isConfirmed: json['isConfirmed'] as bool? ?? true,
    );
  }

  HomeTankInstallationLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? locationMethod,
    bool? isConfirmed,
  }) {
    return HomeTankInstallationLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      locationMethod: locationMethod ?? this.locationMethod,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

/// Firestore Document: home_tanks/{tankId}
/// Private residential water tank owned by an authenticated user.
class HomeTank {
  final String id;
  final String ownerUid;
  final String tankName;
  final HomeTankType tankType;
  final int? capacityLiters;
  final HomeTankInstallationLocation location;
  final String? deviceId; // Associated ESP32 sensor node ID
  final String visibility; // Must always be 'private'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReadingAt;
  final bool isActive;

  // Cached latest sensor readings for fast dashboard rendering
  final double? ph;
  final double? tdsEc;
  final double? turbidity;
  final double? temperature;
  final WaterQualityStatus status;
  final String? notes;

  const HomeTank({
    required this.id,
    required this.ownerUid,
    required this.tankName,
    required this.tankType,
    this.capacityLiters,
    required this.location,
    this.deviceId,
    this.visibility = 'private',
    required this.createdAt,
    required this.updatedAt,
    this.lastReadingAt,
    this.isActive = true,
    this.ph,
    this.tdsEc,
    this.turbidity,
    this.temperature,
    this.status = WaterQualityStatus.noRecentData,
    this.notes,
  });

  bool get hasDevice => deviceId != null && deviceId!.trim().isNotEmpty;

  String get lastUpdatedFormatted {
    if (lastReadingAt == null) return 'No readings yet';
    final diff = DateTime.now().difference(lastReadingAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  HomeTank copyWith({
    String? id,
    String? ownerUid,
    String? tankName,
    HomeTankType? tankType,
    int? capacityLiters,
    HomeTankInstallationLocation? location,
    String? deviceId,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReadingAt,
    bool? isActive,
    double? ph,
    double? tdsEc,
    double? turbidity,
    double? temperature,
    WaterQualityStatus? status,
    String? notes,
  }) {
    return HomeTank(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      tankName: tankName ?? this.tankName,
      tankType: tankType ?? this.tankType,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      location: location ?? this.location,
      deviceId: deviceId ?? this.deviceId,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
      isActive: isActive ?? this.isActive,
      ph: ph ?? this.ph,
      tdsEc: tdsEc ?? this.tdsEc,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'tankName': tankName,
      'tankType': tankType.value,
      'capacityLiters': capacityLiters,
      'location': location.toJson(),
      'deviceId': deviceId,
      'visibility': 'private', // Strictly enforce private
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReadingAt': lastReadingAt?.toIso8601String(),
      'isActive': isActive,
      'ph': ph,
      'tdsEc': tdsEc,
      'turbidity': turbidity,
      'temperature': temperature,
      'status': status.name,
      'notes': notes,
    };
  }

  factory HomeTank.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final lastReading = json['lastReadingAt'] != null
        ? DateTime.tryParse(json['lastReadingAt'].toString())
        : null;

    WaterQualityStatus status;
    if (statusStr != null) {
      status = WaterQualityStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => WaterQualityStatus.withinTypicalRange,
      );
    } else if (lastReading == null && json['ph'] == null && json['tdsEc'] == null) {
      status = WaterQualityStatus.noRecentData;
    } else {
      final ph = (json['ph'] as num?)?.toDouble();
      final tds = (json['tdsEc'] as num?)?.toDouble();
      final turb = (json['turbidity'] as num?)?.toDouble();
      final temp = (json['temperature'] as num?)?.toDouble();

      final isTypical = (ph == null || ParameterThresholds.isPhTypical(ph)) &&
          (tds == null || ParameterThresholds.isTdsTypical(tds)) &&
          (turb == null || ParameterThresholds.isTurbidityTypical(turb)) &&
          (temp == null || ParameterThresholds.isTempTypical(temp));
      status = isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual;
    }

    final locData = json['location'] as Map<String, dynamic>?;
    final location = locData != null
        ? HomeTankInstallationLocation.fromJson(locData)
        : HomeTankInstallationLocation(
            latitude: (json['latitude'] as num?)?.toDouble() ?? 6.9271,
            longitude: (json['longitude'] as num?)?.toDouble() ?? 79.8612,
            address: json['address'] as String? ?? 'Home Location',
          );

    return HomeTank(
      id: json['id'] as String? ?? 'tank_${DateTime.now().millisecondsSinceEpoch}',
      ownerUid: json['ownerUid'] as String? ?? '',
      tankName: json['tankName'] as String? ?? 'My Home Tank',
      tankType: HomeTankTypeExtension.fromString(json['tankType'] as String?),
      capacityLiters: (json['capacityLiters'] as num?)?.toInt(),
      location: location,
      deviceId: json['deviceId'] as String?,
      visibility: 'private',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastReadingAt: lastReading,
      isActive: json['isActive'] as bool? ?? true,
      ph: (json['ph'] as num?)?.toDouble(),
      tdsEc: (json['tdsEc'] as num?)?.toDouble(),
      turbidity: (json['turbidity'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      status: status,
      notes: json['notes'] as String?,
    );
  }
}
