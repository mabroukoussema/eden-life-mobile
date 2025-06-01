import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class NotificationSection extends StatelessWidget {
  final SensorData sensorData;

  const NotificationSection({Key? key, required this.sensorData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> warnings = sensorData.getAllWarningMessages();

    if (warnings.isEmpty) {
      return const Card(
        margin: EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom margin
        child: Padding(
          padding: EdgeInsets.all(12), // Reduced padding
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 20, // Smaller icon
              ),
              SizedBox(width: 12), // Reduced spacing
              Text(
                'All sensors are within normal ranges',
                style: TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom margin
      color: AppTheme.warningColor.withAlpha(
        26,
      ), // Using withAlpha instead of withOpacity
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                  size: 20, // Smaller icon
                ),
                SizedBox(width: 8),
                Text(
                  'Warnings',
                  style: TextStyle(
                    fontSize: 16, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Reduced spacing
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6), // Reduced padding
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.warningColor,
                      size: 18, // Smaller icon
                    ),
                    const SizedBox(width: 6), // Reduced spacing
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          fontSize: 14, // Smaller font
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
