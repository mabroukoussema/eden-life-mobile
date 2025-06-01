class SensorData {
  final double? temperature;
  final double? lux;
  final double? distance;
  final double? ph;
  final String timestamp;

  SensorData({
    this.temperature,
    this.lux,
    this.distance,
    this.ph,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature:
          map['temperature'] != null && map['temperature'] != -999
              ? (map['temperature'] is int
                  ? (map['temperature'] as int).toDouble()
                  : map['temperature'] as double)
              : null,
      lux:
          map['lux'] != null
              ? (map['lux'] is int
                  ? (map['lux'] as int).toDouble()
                  : map['lux'] as double)
              : null,
      distance:
          map['distance'] != null && map['distance'] != -1
              ? (map['distance'] is int
                  ? (map['distance'] as int).toDouble()
                  : map['distance'] as double)
              : null,
      ph:
          map['pH'] != null
              ? (map['pH'] is int
                  ? (map['pH'] as int).toDouble()
                  : map['pH'] as double)
              : null,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'lux': lux,
      'distance': distance,
      'pH': ph,
      'timestamp': timestamp,
    };
  }

  // Helper method to check if temperature is in warning range
  bool isTemperatureWarning() {
    if (temperature == null) return false;
    return temperature! < 25 || temperature! > 35;
  }

  // Helper method to check if lux is in warning range
  bool isLuxWarning() {
    if (lux == null) return false;
    return lux! > 50000;
  }

  // Helper method to check if distance is in warning range
  bool isDistanceWarning() {
    if (distance == null) return false;
    return distance! > 15;
  }

  // Helper method to check if pH is in warning range
  bool isPhWarning() {
    if (ph == null) return false;
    return ph! >= 9.9;
  }

  // Get warning message for temperature
  String? getTemperatureWarningMessage() {
    if (!isTemperatureWarning()) return null;
    if (temperature! < 25) {
      return "Temperature is too low! Should be between 25°C and 35°C";
    }
    return "Temperature is too high! Should be between 25°C and 35°C";
  }

  // Get warning message for lux
  String? getLuxWarningMessage() {
    if (!isLuxWarning()) return null;
    return "Light level is too high! Should be less than 50,000 Lux";
  }

  // Get warning message for distance
  String? getDistanceWarningMessage() {
    if (!isDistanceWarning()) return null;
    return "Distance is too far! Should not exceed 15cm";
  }

  // Get warning message for pH
  String? getPhWarningMessage() {
    if (!isPhWarning()) return null;
    return "pH is too high! Should be less than 9.9";
  }

  // Get all warning messages
  List<String> getAllWarningMessages() {
    List<String> warnings = [];

    String? tempWarning = getTemperatureWarningMessage();
    if (tempWarning != null) warnings.add(tempWarning);

    String? luxWarning = getLuxWarningMessage();
    if (luxWarning != null) warnings.add(luxWarning);

    String? distWarning = getDistanceWarningMessage();
    if (distWarning != null) warnings.add(distWarning);

    String? phWarning = getPhWarningMessage();
    if (phWarning != null) warnings.add(phWarning);

    return warnings;
  }
}
