import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_data.dart';
import '../services/mood_analytics_service.dart';

const _kNavy = Color(0xFF1E3A5F);
const _kSubtitle = Color(0xFF8A9AAB);
const _kBlue = Color(0xFF6BAED4);
const _kPreAnxietyColor = Color(0xFFF18A8A); // Soft red
const _kPostAnxietyColor = Color(0xFF9CC9A9); // Soft green
const _kDailyMoodColor = Color(0xFFF3C456); // Warm yellow

class MoodOverviewWidget extends StatefulWidget {
  const MoodOverviewWidget({Key? key}) : super(key: key);

  @override
  State<MoodOverviewWidget> createState() => _MoodOverviewWidgetState();
}

class _MoodOverviewWidgetState extends State<MoodOverviewWidget> {
  final MoodAnalyticsService _service = MoodAnalyticsService();
  bool _isMonthly = false; // Add toggle later
  List<DailyMoodSummary> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final end = DateTime.now();
    final start =
        _isMonthly
            ? end.subtract(const Duration(days: 30))
            : end.subtract(const Duration(days: 7));
    _data = await _service.fetchMoodAnalytics(start, end);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'Mood Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_isMonthly) {
                      setState(() => _isMonthly = false);
                      _fetchData();
                    }
                  },
                  child: Text(
                    'Weekly',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          !_isMonthly ? FontWeight.w700 : FontWeight.normal,
                      color: !_isMonthly ? _kBlue : _kSubtitle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (!_isMonthly) {
                      setState(() => _isMonthly = true);
                      _fetchData();
                    }
                  },
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          _isMonthly ? FontWeight.w700 : FontWeight.normal,
                      color: _isMonthly ? _kBlue : _kSubtitle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 240,
          padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8),
            ],
          ),
          child:
              _loading
                  ? const Center(
                    child: CircularProgressIndicator(color: _kBlue),
                  )
                  : _data.isEmpty
                  ? const Center(
                    child: Text(
                      'No mood analytics recorded yet.',
                      style: TextStyle(
                        color: _kSubtitle,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : _buildChart(),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(_kPreAnxietyColor, 'Pre-Anxiety (1-10)'),
            const SizedBox(width: 12),
            _buildLegendItem(_kPostAnxietyColor, 'Post (1-10)'),
            const SizedBox(width: 12),
            _buildLegendItem(_kDailyMoodColor, 'Daily Mood (1-5)'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: _kSubtitle)),
      ],
    );
  }

  Widget _buildChart() {
    final now = DateTime.now();
    final start =
        _isMonthly
            ? now.subtract(const Duration(days: 30))
            : now.subtract(const Duration(days: 7));

    // Convert to spots.
    // X is days since start. Y is the value.
    final List<FlSpot> preSpots = [];
    final List<FlSpot> postSpots = [];
    final List<FlSpot> moodSpots = [];

    for (final d in _data) {
      final daysDiff = d.date.difference(start).inDays.toDouble();
      if (d.avgPreAnxiety != null)
        preSpots.add(FlSpot(daysDiff, d.avgPreAnxiety!));
      if (d.avgPostAnxiety != null)
        postSpots.add(FlSpot(daysDiff, d.avgPostAnxiety!));
      if (d.dailyMood != null) {
        // Daily Mood is 1-5, but anxiety is 1-10.
        moodSpots.add(
          FlSpot(daysDiff, d.dailyMood! * 2),
        ); // scale daily mood up visually
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine:
              (value) => const FlLine(color: Color(0xFFF0F5F9), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _isMonthly ? 7 : 1,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox();
                final date = start.add(Duration(days: value.toInt()));
                String text = '${date.month}/${date.day}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(color: _kSubtitle, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (preSpots.isNotEmpty)
            LineChartBarData(
              spots: preSpots,
              isCurved: true,
              color: _kPreAnxietyColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          if (postSpots.isNotEmpty)
            LineChartBarData(
              spots: postSpots,
              isCurved: true,
              color: _kPostAnxietyColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          if (moodSpots.isNotEmpty)
            LineChartBarData(
              spots: moodSpots,
              isCurved: true,
              color: _kDailyMoodColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}
