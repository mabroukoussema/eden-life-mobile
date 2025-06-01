import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child(
    'sensorData',
  );

  // Stream for latest sensor data
  Stream<SensorData> getLatestSensorData() {
    // Always get the latest data by timestamp
    return _databaseRef.orderByChild('timestamp').limitToLast(1).onValue.map((
      event,
    ) {
      try {
        if (event.snapshot.value == null) {
          throw Exception('No data available');
        }

        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        if (data.isEmpty) {
          throw Exception('No data available');
        }

        final String key = data.keys.first;
        final sensorData = SensorData.fromMap(
          data[key] as Map<dynamic, dynamic>,
        );

        return sensorData;
      } catch (e) {
        rethrow;
      }
    });
  }

  // Update a specific sensor value for testing real-time updates
  Future<void> updateSensorValue(
    String keyId,
    SensorValueType valueType,
    double newValue,
  ) async {
    try {
      if (keyId.isEmpty) {
        return;
      }

      // Get the current data first
      final snapshot = await _databaseRef.child(keyId).get();
      if (!snapshot.exists) {
        return;
      }

      // Update only the specified value
      String fieldName;
      switch (valueType) {
        case SensorValueType.temperature:
          fieldName = 'temperature';
          break;
        case SensorValueType.lux:
          fieldName = 'lux';
          break;
        case SensorValueType.distance:
          fieldName = 'distance';
          break;
        case SensorValueType.ph:
          fieldName = 'pH';
          break;
      }

      await _databaseRef.child(keyId).update({fieldName: newValue});
    } catch (e) {
      // Error updating sensor value
    }
  }

  // Get the latest sensor data once (not as a stream)
  Future<SensorData?> getLatestSensorDataOnce() async {
    try {
      // Get the latest data by timestamp
      final snapshot = await _databaseRef.orderByChild('timestamp').limitToLast(1).get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      if (data.isEmpty) {
        return null;
      }

      final String key = data.keys.first;
      final sensorData = SensorData.fromMap(
        data[key] as Map<dynamic, dynamic>,
      );

      return sensorData;
    } catch (e) {
      return null;
    }
  }

  // Get the latest timestamp from the database
  Future<String?> getLatestTimestamp() async {
    try {
      // Get the latest data by timestamp
      final snapshot = await _databaseRef.orderByChild('timestamp').limitToLast(1).get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      if (data.isEmpty) {
        return null;
      }

      final String key = data.keys.first;
      final Map<dynamic, dynamic> sensorData =
          data[key] as Map<dynamic, dynamic>;
      final String timestamp = sensorData['timestamp'] as String;

      return timestamp;
    } catch (e) {
      return null;
    }
  }

  // Get sensor data for a specific time period
  Future<List<SensorData>> getSensorDataByPeriod(TimeFilter period) async {
    try {
      // Get all data
      final snapshot = await _databaseRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value;
      final List<SensorData> sensorDataList = [];

      if (data is Map) {
        data.forEach((key, value) {
          try {
            if (value is Map) {
              final sensorData = SensorData.fromMap(value);
              sensorDataList.add(sensorData);
            }
          } catch (e) {
            // Skip this item and continue
          }
        });
      }

      if (sensorDataList.isEmpty) {
        return [];
      }

      // Sort by timestamp (as integers)
      sensorDataList.sort((a, b) {
        final int aTimestamp = int.tryParse(a.timestamp) ?? 0;
        final int bTimestamp = int.tryParse(b.timestamp) ?? 0;
        return aTimestamp.compareTo(bTimestamp);
      });

      // For time filtering, we'll use the number of entries instead of actual dates
      List<SensorData> filteredList;

      switch (period) {
        case TimeFilter.day:
          // Get the last 24 entries (or fewer if there aren't that many)
          final int startIndex =
              sensorDataList.length > 24 ? sensorDataList.length - 24 : 0;
          filteredList = sensorDataList.sublist(startIndex);
          break;
        case TimeFilter.week:
          // Get the last 168 entries (24*7) (or fewer if there aren't that many)
          final int startIndex =
              sensorDataList.length > 168 ? sensorDataList.length - 168 : 0;
          filteredList = sensorDataList.sublist(startIndex);
          break;
        case TimeFilter.month:
          // Get the last 720 entries (24*30) (or fewer if there aren't that many)
          final int startIndex =
              sensorDataList.length > 720 ? sensorDataList.length - 720 : 0;
          filteredList = sensorDataList.sublist(startIndex);
          break;
      }

      return filteredList;
    } catch (e) {
      return [];
    }
  }
}

enum TimeFilter { day, week, month }

// Sensor value types for updating
enum SensorValueType { temperature, lux, distance, ph }
