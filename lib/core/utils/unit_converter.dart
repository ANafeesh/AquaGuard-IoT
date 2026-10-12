/// Formats and converts water parameter values according to user preferences.
class UnitConverter {
  /// Converts temperature from Celsius to current preference
  static double convertTemperature(double celsius, {bool useFahrenheit = false}) {
    if (!useFahrenheit) return celsius;
    return (celsius * 9 / 5) + 32;
  }

  /// Format temperature with unit
  static String formatTemperature(double celsius, {bool useFahrenheit = false}) {
    final value = convertTemperature(celsius, useFahrenheit: useFahrenheit);
    final unit = useFahrenheit ? '°F' : '°C';
    return '${value.toStringAsFixed(1)} $unit';
  }

  /// Converts TDS/EC (ppm default to µS/cm)
  /// Standard conductivity conversion: 1 ppm ≈ 1.56 µS/cm (442 natural water standard)
  static double convertTds(double ppm, {bool useMicroSiemens = false}) {
    if (!useMicroSiemens) return ppm;
    return ppm * 1.56;
  }

  /// Format TDS/EC with unit
  static String formatTds(double ppm, {bool useMicroSiemens = false}) {
    final value = convertTds(ppm, useMicroSiemens: useMicroSiemens);
    final unit = useMicroSiemens ? 'µS/cm' : 'ppm';
    return '${value.toStringAsFixed(0)} $unit';
  }

  /// Format Turbidity (NTU or JTU)
  static String formatTurbidity(double ntu, {bool useJtu = false}) {
    final unit = useJtu ? 'JTU' : 'NTU';
    return '${ntu.toStringAsFixed(1)} $unit';
  }

  /// Format pH (always unitless)
  static String formatPh(double ph) {
    return ph.toStringAsFixed(2);
  }
}
