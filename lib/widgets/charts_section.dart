import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class ChartsSection extends StatefulWidget {
  const ChartsSection({Key? key}) : super(key: key);

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  final FirebaseService _firebaseService = FirebaseService();
  TimeFilter _selectedTimeFilter = TimeFilter.day;
  String _selectedChart = 'Temperature';
  List<SensorData> _sensorDataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _firebaseService.getSensorDataByPeriod(
        _selectedTimeFilter,
      );

      developer.log('Loaded ${data.length} data points for charts');

      if (data.isEmpty) {
        developer.log('No data available for charts');
      } else {
        developer.log('First data point timestamp: ${data.first.timestamp}');
        developer.log('Last data point timestamp: ${data.last.timestamp}');
      }

      setState(() {
        _sensorDataList = data;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced top margin
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensor Data Charts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12), // Reduced spacing
            _buildChartSelector(),
            const SizedBox(height: 12),
            _buildTimeFilterButtons(),
            const SizedBox(height: 12),
            SizedBox(
              height: 250, // Reduced height to prevent overflow
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Chart',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true, // Makes the dropdown more compact
      ),
      value: _selectedChart,
      items: const [
        DropdownMenuItem(value: 'Temperature', child: Text('Temperature')),
        DropdownMenuItem(value: 'Light', child: Text('Light')),
        DropdownMenuItem(value: 'Distance', child: Text('Distance')),
        DropdownMenuItem(value: 'pH', child: Text('pH')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedChart = value;
          });
        }
      },
    );
  }

  Widget _buildTimeFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildTimeFilterButton('Day', TimeFilter.day)),
        const SizedBox(width: 8),
        Expanded(child: _buildTimeFilterButton('Week', TimeFilter.week)),
        const SizedBox(width: 8),
        Expanded(child: _buildTimeFilterButton('Month', TimeFilter.month)),
      ],
    );
  }

  Widget _buildTimeFilterButton(String label, TimeFilter filter) {
    final isSelected = _selectedTimeFilter == filter;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : AppTheme.textColor,
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: const Size(10, 36), // Smaller minimum width
      ),
      onPressed: () {
        setState(() {
          _selectedTimeFilter = filter;
        });
        _loadData();
      },
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildChart() {
    if (_sensorDataList.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getChartInterval(),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22, // Reduced reserved size
              interval: _getTimeInterval(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < _sensorDataList.length) {
                  final timestamp =
                      int.tryParse(_sensorDataList[value.toInt()].timestamp) ??
                      0;
                  final dateTime = DateTime.fromMillisecondsSinceEpoch(
                    timestamp,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0), // Reduced padding
                    child: Text(
                      _formatDateTime(dateTime),
                      style: const TextStyle(fontSize: 8), // Smaller font
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getChartInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9),
                );
              },
              reservedSize: 30, // Reduced reserved size
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: _sensorDataList.length.toDouble() - 1,
        minY: _getMinY(),
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            color: AppTheme.primaryGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryGreen.withAlpha(51), // 0.2 * 255 = 51
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    final List<FlSpot> spots = [];

    for (int i = 0; i < _sensorDataList.length; i++) {
      final data = _sensorDataList[i];
      double? value;

      switch (_selectedChart) {
        case 'Temperature':
          value = data.temperature;
          break;
        case 'Light':
          value = data.lux;
          break;
        case 'Distance':
          value = data.distance;
          break;
        case 'pH':
          value = data.ph;
          break;
      }

      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return spots;
  }

  double _getMinY() {
    double minValue = double.infinity;

    for (final data in _sensorDataList) {
      double? value;

      switch (_selectedChart) {
        case 'Temperature':
          value = data.temperature;
          break;
        case 'Light':
          value = data.lux;
          break;
        case 'Distance':
          value = data.distance;
          break;
        case 'pH':
          value = data.ph;
          break;
      }

      if (value != null && value < minValue) {
        minValue = value;
      }
    }

    return minValue == double.infinity ? 0 : (minValue - 5);
  }

  double _getMaxY() {
    double maxValue = -double.infinity;

    for (final data in _sensorDataList) {
      double? value;

      switch (_selectedChart) {
        case 'Temperature':
          value = data.temperature;
          break;
        case 'Light':
          value = data.lux;
          break;
        case 'Distance':
          value = data.distance;
          break;
        case 'pH':
          value = data.ph;
          break;
      }

      if (value != null && value > maxValue) {
        maxValue = value;
      }
    }

    return maxValue == -double.infinity ? 100 : (maxValue + 5);
  }

  double _getChartInterval() {
    switch (_selectedChart) {
      case 'Temperature':
        return 5;
      case 'Light':
        return 20;
      case 'Distance':
        return 10;
      case 'pH':
        return 1;
      default:
        return 10;
    }
  }

  double _getTimeInterval() {
    if (_sensorDataList.length <= 5) {
      return 1;
    } else if (_sensorDataList.length <= 20) {
      return 4;
    } else {
      return (_sensorDataList.length / 5).floorToDouble();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Always show only time (HH:mm:ss) regardless of time filter
    return DateFormat('HH:mm:ss').format(dateTime);
  }
}
