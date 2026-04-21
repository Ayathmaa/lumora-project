import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartDataPoint {
  final double x;
  final double y;
  ChartDataPoint(this.x, this.y);
}

class ProgressChartsWidget extends StatelessWidget {
  final List<ChartDataPoint> dailyAnxietyPoints;
  final List<ChartDataPoint> dailyMoodPoints;

  const ProgressChartsWidget({
    super.key,
    required this.dailyAnxietyPoints,
    required this.dailyMoodPoints,
  });

  Widget _buildChart(
    String title,
    List<ChartDataPoint> points,
    Color color,
    double maxY, {
    bool isDays = false,
  }) {
    // Determine bounds and avoid crash if only 1 point exists
    double minX = points.isNotEmpty ? points.first.x : 0;
    double maxX = points.isNotEmpty ? points.last.x : 1;
    if (minX == maxX) {
      if (isDays) {
        minX -= 86400000; // 1 day
        maxX += 86400000;
      } else {
        minX -= 1;
        maxX += 1;
      }
    }

    // Determine interval for labels to prevent overlap
    double? xInterval = isDays ? null : 1;
    if (isDays && points.isNotEmpty) {
      double range = maxX - minX;
      double dayMs = 86400000;
      if (range > dayMs * 5) {
        xInterval = (range / 5).ceilToDouble();
      } else {
        xInterval = dayMs;
      }
      if (xInterval < dayMs) xInterval = dayMs; // Minimum 1 day diff
    }

    double yInterval = maxY >= 100 ? 20.0 : (maxY >= 10 ? 2.0 : 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ), // Very subtle border
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // Slightly darker transparent shadow
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional title header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A3A5C), // Navy Brand Text
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Chart Layout
          SizedBox(
            height: 200,
            child:
                points.isEmpty
                    ? const Center(
                      child: Text(
                        "Not enough data to display yet.",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        minX: minX,
                        maxX: maxX,
                        lineBarsData: [
                          LineChartBarData(
                            spots: points.map((p) => FlSpot(p.x, p.y)).toList(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            preventCurveOverShooting: true,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: color,
                                  strokeWidth: 2.5,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: xInterval,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                // Force integer steps for non-dates
                                if (!isDays && value != value.toInt()) {
                                  return const SizedBox.shrink();
                                }
                                // Avoid edge duplication slightly out of bounds
                                if (value < minX || value > maxX) {
                                  return const SizedBox.shrink();
                                }

                                String text = '';
                                if (isDays) {
                                  final date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt(),
                                      );
                                  text = DateFormat('MM/dd').format(date);
                                } else {
                                  text = value.toInt().toString();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B), // Slate Grey
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: yInterval, // Dynamic vertical spacing
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                // integer check just in case
                                if (value != value.toInt()) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 6,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color(0xFFE2E8F0),
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final yStr = spot.y
                                    .toStringAsFixed(1)
                                    .replaceAll(RegExp(r'\.0$'), '');
                                return LineTooltipItem(
                                  yStr,
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChart(
          "Anxiety Remaining (%)",
          dailyAnxietyPoints,
          const Color(0xFFEF4444),
          100,
          isDays: true,
        ),
        _buildChart(
          "Daily Mood (1-5 Level)",
          dailyMoodPoints,
          const Color(0xFF10B981),
          5,
          isDays: true,
        ),
      ],
    );
  }
}
