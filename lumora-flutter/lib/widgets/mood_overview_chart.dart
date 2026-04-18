import 'package:flutter/material.dart';
import '../services/chart_data_service.dart';
import 'progress_charts.dart';

class MoodOverviewWidget extends StatefulWidget {
  const MoodOverviewWidget({super.key});

  @override
  State<MoodOverviewWidget> createState() => _MoodOverviewWidgetState();
}

class _MoodOverviewWidgetState extends State<MoodOverviewWidget> {
  final ChartDataService _chartService = ChartDataService();

  Map<String, List<ChartDataPoint>>? _chartData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _chartService.fetchChartData();
    if (mounted) {
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chartData == null) {
      return const Center(child: Text("Error loading charts"));
    }

    return ProgressChartsWidget(
      dailyAnxietyPoints: _chartData!['dailyAnxiety'] ?? [],
      dailyMoodPoints: _chartData!['dailyMood'] ?? [],
    );
  }
}
