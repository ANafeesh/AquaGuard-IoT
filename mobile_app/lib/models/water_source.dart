enum WaterQualityStatus {
  withinTypicalRange, // Green - Within expected baseline parameters
  unusual,            // Orange - Parameter shift outside baseline tolerances
  noRecentData,       // Grey/Muted or Attention - Sensor node offline or telemetry missing
}

extension WaterQualityStatusExtension on WaterQualityStatus {
  String get label {
    switch (this) {
      case WaterQualityStatus.withinTypicalRange:
        return 'Within typical range';
      case WaterQualityStatus.unusual:
        return 'Unusual';
      case WaterQualityStatus.noRecentData:
        return 'No recent data';
    }
  }

  /// Compact single-line label for small tags
  String get shortLabel {
    switch (this) {
      case WaterQualityStatus.withinTypicalRange:
        return 'Typical';
      case WaterQualityStatus.unusual:
        return 'Unusual';
      case WaterQualityStatus.noRecentData:
        return 'No Data';
    }
  }
}

class WaterSource {
  final String id;
  final String name;
  final String coordinates;
  final String locationArea;
  final WaterQualityStatus status;
  final String lastUpdated;
  final double ph;
  final int tds; // ppm
  final double turbidity; // NTU
  final double temperature; // °C
  final String description;
  final double latitude;
  final double longitude;

  const WaterSource({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.locationArea,
    required this.status,
    required this.lastUpdated,
    required this.ph,
    required this.tds,
    required this.turbidity,
    required this.temperature,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  WaterSource copyWith({
    String? id,
    String? name,
    String? coordinates,
    String? locationArea,
    WaterQualityStatus? status,
    String? lastUpdated,
    double? ph,
    int? tds,
    double? turbidity,
    double? temperature,
    String? description,
    double? latitude,
    double? longitude,
  }) {
    return WaterSource(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      locationArea: locationArea ?? this.locationArea,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ph: ph ?? this.ph,
      tds: tds ?? this.tds,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
