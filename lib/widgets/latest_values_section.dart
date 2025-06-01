import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'dart:developer' as developer;

class LatestValuesSection extends StatelessWidget {
  final SensorData sensorData;

  const LatestValuesSection({Key? key, required this.sensorData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Print the latest data key ID for debugging
    if (sensorData.timestamp.isNotEmpty) {
      developer.log('LATEST DATA KEY ID: Check Firebase logs for the key');
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ), // Reduced vertical margins
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Sensor Values',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12), // Reduced spacing
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildSensorValue(
                      context,
                      'Temperature',
                      sensorData.temperature != null
                          ? '${sensorData.temperature!.toStringAsFixed(1)}°C'
                          : 'N/A',
                      Icons.thermostat,
                      sensorData.isTemperatureWarning(),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildSensorValue(
                      context,
                      'Light',
                      sensorData.lux != null
                          ? '${sensorData.lux!.toStringAsFixed(1)} lux'
                          : 'N/A',
                      Icons.light_mode,
                      sensorData.isLuxWarning(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced spacing
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildSensorValue(
                      context,
                      'Distance',
                      sensorData.distance != null
                          ? (sensorData.distance == -1.0
                              ? 'N/A' // Handle -1 distance specially
                              : '${sensorData.distance!.toStringAsFixed(1)} cm')
                          : 'N/A',
                      Icons.straighten,
                      sensorData.distance != null && sensorData.distance != -1.0
                          ? sensorData.isDistanceWarning()
                          : false,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildSensorValue(
                      context,
                      'pH',
                      sensorData.ph != null
                          ? sensorData.ph!.toStringAsFixed(1)
                          : 'N/A',
                      Icons.water_drop,
                      sensorData.isPhWarning(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last updated: ${_formatTimestamp(sensorData.timestamp)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorValue(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isWarning,
  ) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color:
            isWarning
                ? AppTheme.warningColor.withAlpha(26) // 0.1 * 255 = ~26
                : AppTheme.primaryGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    isWarning ? AppTheme.warningColor : AppTheme.primaryGreen,
                size: 18, // Smaller icon
              ),
              const SizedBox(width: 6), // Reduced spacing
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13, // Smaller font
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isWarning ? AppTheme.warningColor : AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      int timestampValue;
      if (timestamp.length <= 10) {
        // Seconds format
        timestampValue = int.parse(timestamp);
        timestampValue *= 1000; // Convert to milliseconds
      } else {
        // Already in milliseconds
        timestampValue = int.parse(timestamp);
      }

      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
        timestampValue,
      );
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
