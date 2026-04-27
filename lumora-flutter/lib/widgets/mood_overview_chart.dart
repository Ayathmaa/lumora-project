import 'package:flutter/material.dart';
import '../services/chart_data_service.dart';
import 'progress_charts.dart';

class MoodOverviewWidget extends StatelessWidget {
  final String? userId;
  final bool showAnxiety;
  final bool showMood;

  const MoodOverviewWidget({
    super.key,
    this.userId,
    this.showAnxiety = true,
    this.showMood = true,
  });

  @override
  Widget build(BuildContext context) {
    final ChartDataService chartService = ChartDataService();

    if (!showAnxiety && !showMood) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, List<ChartDataPoint>>>(
      stream: chartService.getChartDataStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading charts"));
        }

        final chartData = snapshot.data;
        if (chartData == null) {
          return const Center(child: Text("No chart data available"));
        }

        return ProgressChartsWidget(
          dailyAnxietyPoints: showAnxiety ? chartData['dailyAnxiety'] : null,
          dailyMoodPoints: showMood ? chartData['dailyMood'] : null,
        );
      },
    );
  }
}
