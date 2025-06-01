import 'dart:async';
import 'dart:math';
import '../models/sensor_data.dart';
import 'firebase_service.dart';

/// A mock service that generates random sensor data for testing
class MockService {
  final _random = Random();
  final _controller = StreamController<SensorData>.broadcast();
  Timer? _timer;
  final List<SensorData> _historicalData = [];
  
  Stream<SensorData> get latestSensorData => _controller.stream;
  
  MockService() {
    // Generate initial historical data
    _generateHistoricalData();
    
    // Start generating real-time data
    _startGeneratingData();
  }
  
  void _startGeneratingData() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final newData = _generateRandomSensorData();
      _historicalData.add(newData);
      
      // Keep only the last 100 data points
      if (_historicalData.length > 100) {
        _historicalData.removeAt(0);
      }
      
      _controller.add(newData);
    });
  }
  
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
  
  SensorData _generateRandomSensorData() {
    // Generate random values with occasional warnings
    final temp = _random.nextDouble() * 40 - 5; // -5 to 35
    final lux = _random.nextDouble() * 150; // 0 to 150
    final distance = _random.nextDouble() * 60; // 0 to 60
    
    // Sometimes generate null pH to simulate missing data
    final hasPh = _random.nextBool();
    final ph = hasPh ? 4 + _random.nextDouble() * 10 : null; // 4 to 14 or null
    
    return SensorData(
      temperature: temp,
      lux: lux,
      distance: distance,
      ph: ph,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
  
  void _generateHistoricalData() {
    // Generate data for the past week with 1-hour intervals
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    DateTime current = oneWeekAgo;
    while (current.isBefore(now)) {
      final data = _generateRandomSensorData();
      
      // Override the timestamp with the historical time
      final historicalData = SensorData(
        temperature: data.temperature,
        lux: data.lux,
        distance: data.distance,
        ph: data.ph,
        timestamp: current.millisecondsSinceEpoch.toString(),
      );
      
      _historicalData.add(historicalData);
      current = current.add(const Duration(hours: 1));
    }
  }
  
  Future<List<SensorData>> getSensorDataByPeriod(TimeFilter period) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final DateTime now = DateTime.now();
    final DateTime threshold = _getThresholdDate(now, period);
    
    return _historicalData.where((data) {
      final timestamp = int.tryParse(data.timestamp) ?? 0;
      final dataTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return dataTime.isAfter(threshold);
    }).toList();
  }
  
  DateTime _getThresholdDate(DateTime now, TimeFilter period) {
    switch (period) {
      case TimeFilter.day:
        return now.subtract(const Duration(days: 1));
      case TimeFilter.week:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.month:
        return now.subtract(const Duration(days: 30));
    }
  }
}
