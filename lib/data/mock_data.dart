import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/community_observation.dart';
import '../models/alert_item.dart';

class MockData {
  static const String prototypeNotice = 
      'Simulation Mode: Realistic mock data used for demonstration. No physical IoT hardware or Firebase backend is connected.';

  // Water Sources
  static List<WaterSource> waterSources = [
    WaterSource(
      id: 'ws-1',
      name: 'Lake View Point',
      type: WaterSourceType.lake,
      latitude: 6.9271,
      longitude: 79.8612,
      createdBy: 'system_admin',
      createdAt: DateTime(2026, 1, 1),
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ph: 7.2,
      tdsEc: 320.0,
      turbidity: 3.4,
      temperature: 28.4,
      status: WaterQualityStatus.withinTypicalRange,
      description: 'Primary community freshwater lake monitored for ambient aquatic indicators.',
    ),
    WaterSource(
      id: 'ws-2',
      name: 'Riverside',
      type: WaterSourceType.river,
      latitude: 6.9380,
      longitude: 79.8720,
      createdBy: 'system_admin',
      createdAt: DateTime(2026, 1, 1),
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 14)),
      ph: 6.9,
      tdsEc: 410.0,
      turbidity: 6.8,
      temperature: 29.1,
      status: WaterQualityStatus.unusual,
      description: 'Slow-flowing river tributary downstream from seasonal runoff channels.',
    ),
    WaterSource(
      id: 'ws-3',
      name: 'Community Well',
      type: WaterSourceType.well,
      latitude: 6.9150,
      longitude: 79.8550,
      createdBy: 'system_admin',
      createdAt: DateTime(2026, 1, 1),
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ph: 6.4,
      tdsEc: 485.0,
      turbidity: 8.2,
      temperature: 27.8,
      status: WaterQualityStatus.unusual,
      description: 'Shared groundwater well used for non-potable communal washing and garden supply.',
    ),
    WaterSource(
      id: 'ws-4',
      name: 'North Reservoir',
      type: WaterSourceType.reservoir,
      latitude: 6.9450,
      longitude: 79.8650,
      createdBy: 'system_admin',
      createdAt: DateTime(2026, 1, 1),
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ph: 7.4,
      tdsEc: 290.0,
      turbidity: 2.8,
      temperature: 26.9,
      status: WaterQualityStatus.withinTypicalRange,
      description: 'Elevated protected catchment basin supplying regional municipal distribution.',
    ),
    WaterSource(
      id: 'ws-5',
      name: 'Village Water Point',
      type: WaterSourceType.other,
      latitude: 6.9050,
      longitude: 79.8450,
      createdBy: 'system_admin',
      createdAt: DateTime(2026, 1, 1),
      lastReadingAt: DateTime.now().subtract(const Duration(hours: 3)),
      ph: 7.1,
      tdsEc: 335.0,
      turbidity: 3.1,
      temperature: 28.0,
      status: WaterQualityStatus.noRecentData,
      description: 'Public tap and spring outlet maintained by village environmental group.',
    ),
  ];

  // Default active water source
  static WaterSource get activeSource => waterSources[0];

  // Parameters for Lake View Point
  static List<ParameterReading> getLakeViewReadings() {
    return [
      ParameterReading.fromType(
        type: ParameterType.ph,
        value: 7.2,
        status: WaterQualityStatus.withinTypicalRange,
      ),
      ParameterReading.fromType(
        type: ParameterType.tds,
        value: 320,
        status: WaterQualityStatus.withinTypicalRange,
      ),
      ParameterReading.fromType(
        type: ParameterType.turbidity,
        value: 3.4,
        status: WaterQualityStatus.withinTypicalRange,
      ),
      ParameterReading.fromType(
        type: ParameterType.temperature,
        value: 28.4,
        status: WaterQualityStatus.withinTypicalRange,
      ),
    ];
  }

  // Historical data for charts (time series for Lake View Point)
  static Map<String, List<HistoricalPoint>> historicalPh = {
    '24H': [
      HistoricalPoint('00:00', 7.1),
      HistoricalPoint('04:00', 7.0),
      HistoricalPoint('08:00', 7.3),
      HistoricalPoint('12:00', 7.4),
      HistoricalPoint('16:00', 7.2),
      HistoricalPoint('20:00', 7.2),
    ],
    '7D': [
      HistoricalPoint('Mon', 7.0),
      HistoricalPoint('Tue', 7.2),
      HistoricalPoint('Wed', 7.1),
      HistoricalPoint('Thu', 7.3),
      HistoricalPoint('Fri', 7.4),
      HistoricalPoint('Sat', 7.2),
      HistoricalPoint('Sun', 7.2),
    ],
    '30D': [
      HistoricalPoint('W1', 7.0),
      HistoricalPoint('W2', 7.2),
      HistoricalPoint('W3', 7.1),
      HistoricalPoint('W4', 7.2),
    ],
    'All': [
      HistoricalPoint('Jan', 7.1),
      HistoricalPoint('Feb', 7.3),
      HistoricalPoint('Mar', 7.2),
    ],
  };

  static Map<String, List<HistoricalPoint>> historicalTds = {
    '24H': [
      HistoricalPoint('00:00', 310),
      HistoricalPoint('04:00', 315),
      HistoricalPoint('08:00', 325),
      HistoricalPoint('12:00', 330),
      HistoricalPoint('16:00', 320),
      HistoricalPoint('20:00', 320),
    ],
    '7D': [
      HistoricalPoint('Mon', 305),
      HistoricalPoint('Tue', 315),
      HistoricalPoint('Wed', 320),
      HistoricalPoint('Thu', 328),
      HistoricalPoint('Fri', 322),
      HistoricalPoint('Sat', 318),
      HistoricalPoint('Sun', 320),
    ],
    '30D': [
      HistoricalPoint('W1', 310),
      HistoricalPoint('W2', 325),
      HistoricalPoint('W3', 318),
      HistoricalPoint('W4', 320),
    ],
  };

  static Map<String, List<HistoricalPoint>> historicalTurbidity = {
    '24H': [
      HistoricalPoint('00:00', 3.1),
      HistoricalPoint('04:00', 3.0),
      HistoricalPoint('08:00', 3.6),
      HistoricalPoint('12:00', 3.8),
      HistoricalPoint('16:00', 3.5),
      HistoricalPoint('20:00', 3.4),
    ],
    '7D': [
      HistoricalPoint('Mon', 2.8),
      HistoricalPoint('Tue', 3.1),
      HistoricalPoint('Wed', 3.5),
      HistoricalPoint('Thu', 4.0),
      HistoricalPoint('Fri', 3.6),
      HistoricalPoint('Sat', 3.3),
      HistoricalPoint('Sun', 3.4),
    ],
    '30D': [
      HistoricalPoint('W1', 3.0),
      HistoricalPoint('W2', 3.6),
      HistoricalPoint('W3', 3.3),
      HistoricalPoint('W4', 3.4),
    ],
  };

  static Map<String, List<HistoricalPoint>> historicalTemperature = {
    '24H': [
      HistoricalPoint('00:00', 26.8),
      HistoricalPoint('04:00', 26.2),
      HistoricalPoint('08:00', 27.5),
      HistoricalPoint('12:00', 29.1),
      HistoricalPoint('16:00', 28.8),
      HistoricalPoint('20:00', 28.4),
    ],
    '7D': [
      HistoricalPoint('Mon', 27.5),
      HistoricalPoint('Tue', 28.0),
      HistoricalPoint('Wed', 28.2),
      HistoricalPoint('Thu', 28.6),
      HistoricalPoint('Fri', 28.5),
      HistoricalPoint('Sat', 28.1),
      HistoricalPoint('Sun', 28.4),
    ],
    '30D': [
      HistoricalPoint('W1', 27.5),
      HistoricalPoint('W2', 28.0),
      HistoricalPoint('W3', 28.3),
      HistoricalPoint('W4', 28.4),
    ],
  };

  // Trend Aliases
  static Map<String, List<HistoricalPoint>> get phTrends => historicalPh;
  static Map<String, List<HistoricalPoint>> get tdsTrends => historicalTds;
  static Map<String, List<HistoricalPoint>> get turbidityTrends => historicalTurbidity;
  static Map<String, List<HistoricalPoint>> get tempTrends => historicalTemperature;

  // Recent Alerts
  static List<AlertItem> alerts = [
    AlertItem(
      id: 'alt-1',
      sourceId: 'ws-2',
      measurementId: 'm-alt-1',
      parameter: 'Turbidity',
      value: 6.8,
      message: 'Unusual water-quality measurement detected at this location.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      acknowledged: false,
      waterSourceName: 'Riverside',
      severity: WaterQualityStatus.unusual,
      investigationAdvice: 'Turbidity level shifted from typical baseline. Field re-check suggested.',
    ),
    AlertItem(
      id: 'alt-2',
      sourceId: 'ws-3',
      measurementId: 'm-alt-2',
      parameter: 'TDS/EC',
      value: 485.0,
      message: 'Unusual water-quality measurement detected at this location.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      acknowledged: false,
      waterSourceName: 'Community Well',
      severity: WaterQualityStatus.unusual,
      investigationAdvice: 'Parameters shifted outside baseline. Re-check scheduled for this afternoon.',
    ),
    AlertItem(
      id: 'alt-3',
      sourceId: 'ws-3',
      measurementId: 'm-alt-3',
      parameter: 'pH Level',
      value: 6.4,
      message: 'Unusual water-quality measurement detected at this location.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      acknowledged: true,
      waterSourceName: 'Community Well',
      severity: WaterQualityStatus.unusual,
      investigationAdvice: 'Observation recorded to public community ledger.',
    ),
    AlertItem(
      id: 'alt-4',
      sourceId: 'ws-4',
      measurementId: 'm-alt-4',
      parameter: 'Temperature',
      value: 26.9,
      message: 'Unusual water-quality measurement detected at this location.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      acknowledged: true,
      waterSourceName: 'North Reservoir',
      severity: WaterQualityStatus.withinTypicalRange,
      investigationAdvice: 'Baseline indicators stable and aligned with historical seasonal averages.',
    ),
  ];

  // Community Observations
  static List<CommunityObservation> observations = [
    CommunityObservation(
      id: 'obs-1',
      waterSourceName: 'Lake View Point',
      locationArea: 'Near North Jetty',
      userName: 'Elena Rostova',
      userAvatar: 'ER',
      timeAgo: '2 hours ago',
      notes: 'Water appears clearer than the previous observation. No unusual odor or surface film detected.',
      ph: 7.2,
      turbidity: 3.4,
      status: WaterQualityStatus.withinTypicalRange,
      hasPhoto: true,
      helpfulCount: 8,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CommunityObservation(
      id: 'obs-2',
      waterSourceName: 'Community Well',
      locationArea: 'South Ward Perimeter',
      userName: 'Marcus Chen',
      userAvatar: 'MC',
      timeAgo: '3 hours ago',
      notes: 'Unusual turbidity measurement observed. Sediment visible after high morning extraction.',
      ph: 6.4,
      tds: 485,
      turbidity: 8.2,
      status: WaterQualityStatus.unusual,
      hasPhoto: true,
      helpfulCount: 14,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityObservation(
      id: 'obs-3',
      waterSourceName: 'Riverside',
      locationArea: 'Bikeway Bridge Pier',
      userName: 'Aisha Perera',
      userAvatar: 'AP',
      timeAgo: '5 hours ago',
      notes: 'Slight cloudy drift noticed near runoff drain outlet. Flow rate is normal today.',
      ph: 6.9,
      turbidity: 6.8,
      status: WaterQualityStatus.unusual,
      hasPhoto: false,
      helpfulCount: 5,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    CommunityObservation(
      id: 'obs-4',
      waterSourceName: 'Village Water Point',
      locationArea: 'Common Square',
      userName: 'David Kalu',
      userAvatar: 'DK',
      timeAgo: 'Yesterday',
      notes: 'Morning community draw sample tested within expected range. Consistent pressure and clarity.',
      ph: 7.1,
      tds: 335,
      turbidity: 3.1,
      status: WaterQualityStatus.withinTypicalRange,
      hasPhoto: false,
      helpfulCount: 9,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
