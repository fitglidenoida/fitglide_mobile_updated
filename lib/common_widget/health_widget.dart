import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../services/health_service.dart';

class HealthWidget extends StatefulWidget {
  final HealthService healthService;
  final Function(List<HealthDataPoint>) onHealthDataFetched;

  const HealthWidget({super.key, required this.healthService, required this.onHealthDataFetched});

  @override
  _HealthWidgetState createState() => _HealthWidgetState();
}

class _HealthWidgetState extends State<HealthWidget> {
  List<HealthDataPoint> _healthDataList = [];
  bool _isLoading = false;
  String _status = "Fetching data...";

  @override
  void initState() {
    super.initState();
    _fetchHealthData(); // Fetch data on initialization
  }

  Future<void> _fetchHealthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      _healthDataList = await widget.healthService.fetchHealthData(yesterday, now);
      _status = "Data fetched successfully";

      // Call the callback with the fetched data
      widget.onHealthDataFetched(_healthDataList);
    } catch (e) {
      _status = "Failed to fetch data: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchHealthData,
      child: Column(
        children: [
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!_isLoading)
            Text(_status),
          if (!_isLoading && _healthDataList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _healthDataList.length,
                itemBuilder: (context, index) {
                  var dataPoint = _healthDataList[index];
                  return ListTile(
                    title: Text("${dataPoint.typeString}: ${dataPoint.value}"),
                    subtitle: Text('${dataPoint.dateFrom} - ${dataPoint.dateTo}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}