class KnownLocation {
  final String name;
  final String province;
  final double latitude;
  final double longitude;
  final String defaultWaterBody;

  const KnownLocation({
    required this.name,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.defaultWaterBody,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
}

class SriLankaLocations {
  static const List<KnownLocation> catalog = [
    KnownLocation(
      name: 'Kandy',
      province: 'Central Province',
      latitude: 7.2906,
      longitude: 80.6337,
      defaultWaterBody: 'Kandy Lake (Bogambara)',
    ),
    KnownLocation(
      name: 'Colombo',
      province: 'Western Province',
      latitude: 6.9271,
      longitude: 79.8612,
      defaultWaterBody: 'Beira Lake / Kelani River',
    ),
    KnownLocation(
      name: 'Nuwara Eliya',
      province: 'Central Highlands',
      latitude: 6.9497,
      longitude: 80.7891,
      defaultWaterBody: 'Lake Gregory',
    ),
    KnownLocation(
      name: 'Galle',
      province: 'Southern Province',
      latitude: 6.0535,
      longitude: 80.2210,
      defaultWaterBody: 'Gin Ganga / Galle Coastal Catchment',
    ),
    KnownLocation(
      name: 'Anuradhapura',
      province: 'North Central Province',
      latitude: 8.3114,
      longitude: 80.4037,
      defaultWaterBody: 'Tissa Wewa Reservoir',
    ),
    KnownLocation(
      name: 'Jaffna',
      province: 'Northern Province',
      latitude: 9.6615,
      longitude: 80.0255,
      defaultWaterBody: 'Jaffna Lagoon Catchment',
    ),
    KnownLocation(
      name: 'Negombo',
      province: 'Western Province',
      latitude: 7.2008,
      longitude: 79.8736,
      defaultWaterBody: 'Negombo Lagoon',
    ),
    KnownLocation(
      name: 'Matara',
      province: 'Southern Province',
      latitude: 5.9549,
      longitude: 80.5550,
      defaultWaterBody: 'Nilwala River Basin',
    ),
    KnownLocation(
      name: 'Trincomalee',
      province: 'Eastern Province',
      latitude: 8.5874,
      longitude: 81.2152,
      defaultWaterBody: 'Koddiyar Bay Catchment',
    ),
    KnownLocation(
      name: 'Batticaloa',
      province: 'Eastern Province',
      latitude: 7.7310,
      longitude: 81.6747,
      defaultWaterBody: 'Batticaloa Lagoon',
    ),
    KnownLocation(
      name: 'Kurunegala',
      province: 'North Western Province',
      latitude: 7.4863,
      longitude: 80.3623,
      defaultWaterBody: 'Kurunegala Lake Basin',
    ),
    KnownLocation(
      name: 'Ratnapura',
      province: 'Sabaragamuwa Province',
      latitude: 6.7056,
      longitude: 80.3847,
      defaultWaterBody: 'Kalu Ganga River',
    ),
    KnownLocation(
      name: 'Badulla',
      province: 'Uva Province',
      latitude: 6.9934,
      longitude: 81.0550,
      defaultWaterBody: 'Badulu Oya Catchment',
    ),
    KnownLocation(
      name: 'Polonnaruwa',
      province: 'North Central Province',
      latitude: 7.9403,
      longitude: 81.0188,
      defaultWaterBody: 'Parakrama Samudra Basin',
    ),
  ];

  /// Find matching known location by name or query (case-insensitive)
  static KnownLocation? findByName(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    for (final loc in catalog) {
      if (loc.name.toLowerCase() == clean ||
          clean.contains(loc.name.toLowerCase()) ||
          loc.defaultWaterBody.toLowerCase().contains(clean)) {
        return loc;
      }
    }
    return null;
  }
}
