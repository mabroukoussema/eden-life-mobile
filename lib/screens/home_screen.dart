import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/notification_section.dart';
import '../widgets/latest_values_section.dart';
import '../widgets/charts_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  SensorData? _latestSensorData;
  bool _isLoading = true;
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupDataListener();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  void _setupDataListener() {
    try {
      _dataSubscription = _firebaseService.getLatestSensorData().listen(
        (sensorData) {
          setState(() {
            _latestSensorData = sensorData;
            _isLoading = false;
          });

          // Check for warnings and send notifications
          _notificationService.checkAndNotify(sensorData);
        },
        onError: (error) {
          debugPrint('Error listening to sensor data: $error');
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      debugPrint('Error setting up data listener: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eden Life'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _latestSensorData == null
              ? const Center(child: Text('No sensor data available'))
              : RefreshIndicator(
                onRefresh: () async {
                  // This is just for UX, the real-time listener will update the data
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                    ), // Add bottom padding for scrolling
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NotificationSection(sensorData: _latestSensorData!),
                        LatestValuesSection(sensorData: _latestSensorData!),
                        const ChartsSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
