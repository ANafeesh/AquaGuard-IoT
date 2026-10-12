/// Stores user application and unit preferences
class UserPreferences {
  final bool useFahrenheit;
  final bool useMicroSiemens;
  final bool useJtu;
  final bool isDarkMode;
  final bool isDemoMode;

  const UserPreferences({
    this.useFahrenheit = false,
    this.useMicroSiemens = false,
    this.useJtu = false,
    this.isDarkMode = false,
    this.isDemoMode = false,
  });

  String get tempUnitLabel => useFahrenheit ? '°F' : '°C';
  String get tdsUnitLabel => useMicroSiemens ? 'µS/cm' : 'ppm';
  String get turbidityUnitLabel => useJtu ? 'JTU' : 'NTU';

  UserPreferences copyWith({
    bool? useFahrenheit,
    bool? useMicroSiemens,
    bool? useJtu,
    bool? isDarkMode,
    bool? isDemoMode,
  }) {
    return UserPreferences(
      useFahrenheit: useFahrenheit ?? this.useFahrenheit,
      useMicroSiemens: useMicroSiemens ?? this.useMicroSiemens,
      useJtu: useJtu ?? this.useJtu,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useFahrenheit': useFahrenheit,
      'useMicroSiemens': useMicroSiemens,
      'useJtu': useJtu,
      'isDarkMode': isDarkMode,
      'isDemoMode': isDemoMode,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      useFahrenheit: json['useFahrenheit'] as bool? ?? false,
      useMicroSiemens: json['useMicroSiemens'] as bool? ?? false,
      useJtu: json['useJtu'] as bool? ?? false,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isDemoMode: json['isDemoMode'] as bool? ?? false,
    );
  }
}
