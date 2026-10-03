import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/community_observation.dart';
import '../models/alert_item.dart';

class MockData {
  static const String prototypeNotice = 
      'UI/UX Prototype Mode: Realistic mock data used for demonstration. No physical IoT hardware or Firebase backend is connected.';

  // Water Sources
  static List<WaterSource> waterSources = [
    const WaterSource(
      id: 'ws-1',
      name: 'Lake View Point',
      coordinates: '6.9271° N, 79.8612° E (Mock GPS)',
      locationArea: 'Central Reservoir District',
      status: WaterQualityStatus.withinTypicalRange,
      lastUpdated: 'Updated 2 min ago',
      ph: 7.2,
      tds: 320,
      turbidity: 3.4,
      temperature: 28.4,
      description: 'Primary community freshwater lake monitored for ambient aquatic indicators.',
      latitude: 6.9271,
      longitude: 79.8612,
    ),
    const WaterSource(
      id: 'ws-2',
      name: 'Riverside',
      coordinates: '6.9380° N, 79.8720° E (Mock GPS)',
      locationArea: 'East Riverbank Reach',
      status: WaterQualityStatus.unusual,
      lastUpdated: 'Updated 14 min ago',
      ph: 6.9,
      tds: 410,
      turbidity: 6.8,
      temperature: 29.1,
      description: 'Slow-flowing river tributary downstream from seasonal runoff channels.',
      latitude: 6.9380,
      longitude: 79.8720,
    ),
    const WaterSource(
      id: 'ws-3',
      name: 'Community Well',
      coordinates: '6.9150° N, 79.8550° E (Mock GPS)',
      locationArea: 'South Ward Community Center',
      status: WaterQualityStatus.unusual,
      lastUpdated: 'Updated 45 min ago',
      ph: 6.4,
      tds: 485,
      turbidity: 8.2,
      temperature: 27.8,
      description: 'Shared groundwater well used for non-potable communal washing and garden supply.',
      latitude: 6.9150,
      longitude: 79.8550,
    ),
    const WaterSource(
      id: 'ws-4',
      name: 'North Reservoir',
      coordinates: '6.9450° N, 79.8650° E (Mock GPS)',
      locationArea: 'Highland Catchment',
      status: WaterQualityStatus.withinTypicalRange,
      lastUpdated: 'Updated 5 min ago',
      ph: 7.4,
      tds: 290,
      turbidity: 2.8,
      temperature: 26.9,
      description: 'Elevated protected catchment basin supplying regional municipal distribution.',
      latitude: 6.9450,
      longitude: 79.8650,
    ),
    const WaterSource(
      id: 'ws-5',
      name: 'Village Water Point',
      coordinates: '6.9050° N, 79.8450° E (Mock GPS)',
      locationArea: 'West Village Common',
      status: WaterQualityStatus.noRecentData,
      lastUpdated: 'Updated 3 hours ago',
      ph: 7.1,
      tds: 335,
      turbidity: 3.1,
      temperature: 28.0,
      description: 'Public tap and spring outlet maintained by village elders and environmental group.',
      latitude: 6.9050,
      longitude: 79.8450,
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

  // Trend historical points
  static const Map<String, List<HistoricalPoint>> phTrends = {
    '24H': [
      HistoricalPoint('00:00', 7.1),
      HistoricalPoint('04:00', 7.15),
      HistoricalPoint('08:00', 7.3),
      HistoricalPoint('12:00', 7.25),
      HistoricalPoint('16:00', 7.2),
      HistoricalPoint('20:00', 7.18),
      HistoricalPoint('Now', 7.2),
    ],
    '7D': [
      HistoricalPoint('Mon', 7.0),
      HistoricalPoint('Tue', 7.1),
      HistoricalPoint('Wed', 7.2),
      HistoricalPoint('Thu', 7.15),
      HistoricalPoint('Fri', 7.3),
      HistoricalPoint('Sat', 7.2),
      HistoricalPoint('Sun', 7.2),
    ],
    '30D': [
      HistoricalPoint('W1', 7.05),
      HistoricalPoint('W2', 7.18),
      HistoricalPoint('W3', 7.22),
      HistoricalPoint('W4', 7.2),
    ],
  };

  static const Map<String, List<HistoricalPoint>> tdsTrends = {
    '24H': [
      HistoricalPoint('00:00', 310),
      HistoricalPoint('04:00', 315),
      HistoricalPoint('08:00', 325),
      HistoricalPoint('12:00', 330),
      HistoricalPoint('16:00', 322),
      HistoricalPoint('20:00', 318),
      HistoricalPoint('Now', 320),
    ],
    '7D': [
      HistoricalPoint('Mon', 305),
      HistoricalPoint('Tue', 312),
      HistoricalPoint('Wed', 318),
      HistoricalPoint('Thu', 325),
      HistoricalPoint('Fri', 320),
      HistoricalPoint('Sat', 319),
      HistoricalPoint('Sun', 320),
    ],
    '30D': [
      HistoricalPoint('W1', 298),
      HistoricalPoint('W2', 310),
      HistoricalPoint('W3', 318),
      HistoricalPoint('W4', 320),
    ],
  };

  static const Map<String, List<HistoricalPoint>> turbidityTrends = {
    '24H': [
      HistoricalPoint('00:00', 3.1),
      HistoricalPoint('04:00', 3.2),
      HistoricalPoint('08:00', 3.6),
      HistoricalPoint('12:00', 3.5),
      HistoricalPoint('16:00', 3.3),
      HistoricalPoint('20:00', 3.4),
      HistoricalPoint('Now', 3.4),
    ],
    '7D': [
      HistoricalPoint('Mon', 2.9),
      HistoricalPoint('Tue', 3.0),
      HistoricalPoint('Wed', 3.4),
      HistoricalPoint('Thu', 3.8),
      HistoricalPoint('Fri', 3.5),
      HistoricalPoint('Sat', 3.3),
      HistoricalPoint('Sun', 3.4),
    ],
    '30D': [
      HistoricalPoint('W1', 3.0),
      HistoricalPoint('W2', 3.2),
      HistoricalPoint('W3', 3.6),
      HistoricalPoint('W4', 3.4),
    ],
  };

  static const Map<String, List<HistoricalPoint>> tempTrends = {
    '24H': [
      HistoricalPoint('00:00', 26.8),
      HistoricalPoint('04:00', 26.2),
      HistoricalPoint('08:00', 27.5),
      HistoricalPoint('12:00', 29.2),
      HistoricalPoint('16:00', 29.0),
      HistoricalPoint('20:00', 28.1),
      HistoricalPoint('Now', 28.4),
    ],
    '7D': [
      HistoricalPoint('Mon', 27.8),
      HistoricalPoint('Tue', 28.1),
      HistoricalPoint('Wed', 28.5),
      HistoricalPoint('Thu', 28.2),
      HistoricalPoint('Fri', 28.0),
      HistoricalPoint('Sat', 28.6),
      HistoricalPoint('Sun', 28.4),
    ],
    '30D': [
      HistoricalPoint('W1', 27.5),
      HistoricalPoint('W2', 28.0),
      HistoricalPoint('W3', 28.3),
      HistoricalPoint('W4', 28.4),
    ],
  };

  // Recent Alerts
  static List<AlertItem> alerts = [
    const AlertItem(
      id: 'alt-1',
      title: 'Unusual Reading Detected',
      description: 'An unusual turbidity change was detected at River Side Point.',
      timeAgo: '2 hours ago',
      severity: WaterQualityStatus.unusual,
      waterSourceName: 'Riverside',
      isToday: true,
      investigationAdvice: 'Unusual measurement detected. Further investigation may be required.',
    ),
    const AlertItem(
      id: 'alt-2',
      title: 'Elevated TDS Level Observation',
      description: 'Community monitoring reported higher mineral readings at Community Well.',
      timeAgo: '4 hours ago',
      severity: WaterQualityStatus.unusual,
      waterSourceName: 'Community Well',
      isToday: true,
      investigationAdvice: 'Parameters shifted outside baseline. Re-check scheduled for this afternoon.',
    ),
    const AlertItem(
      id: 'alt-3',
      title: 'New Community Observation',
      description: 'A new observation was submitted for Community Well by member David K.',
      timeAgo: 'Yesterday',
      severity: WaterQualityStatus.withinTypicalRange,
      waterSourceName: 'Community Well',
      isToday: false,
      investigationAdvice: 'Observation recorded to public community ledger.',
    ),
    const AlertItem(
      id: 'alt-4',
      title: 'Telemetry Diagnostics Complete',
      description: 'Scheduled simulated diagnostic ping completed for North Reservoir.',
      timeAgo: '2 days ago',
      severity: WaterQualityStatus.withinTypicalRange,
      waterSourceName: 'North Reservoir',
      isToday: false,
      investigationAdvice: 'Baseline indicators stable and aligned with historical seasonal averages.',
    ),
  ];

  // Community Observations
  static List<CommunityObservation> observations = [
    const CommunityObservation(
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
    ),
    const CommunityObservation(
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
    ),
    const CommunityObservation(
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
    ),
    const CommunityObservation(
      id: 'obs-4',
      waterSourceName: 'Village Water Point',
      locationArea: 'Common Square',
      userName: 'David Kalu',
      userAvatar: 'DK',
      timeAgo: 'Yesterday',
      notes: 'Morning community draw sample tested clean. Consistent pressure and clarity.',
      ph: 7.1,
      tds: 335,
      turbidity: 3.1,
      status: WaterQualityStatus.withinTypicalRange,
      hasPhoto: false,
      helpfulCount: 9,
    ),
  ];
}
