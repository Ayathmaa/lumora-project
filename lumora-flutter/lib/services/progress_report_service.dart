import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/progress_charts.dart';
import 'chart_data_service.dart';

class ProgressReportService {
  final ChartDataService _chartDataService;

  ProgressReportService({ChartDataService? chartDataService})
    : _chartDataService = chartDataService ?? ChartDataService();

  Future<Uint8List> buildProgressReportPdf([String? userId]) async {
    final chartData = await _chartDataService.fetchChartData(userId);
    final anxietyPoints = _validPoints(chartData['dailyAnxiety'] ?? []);
    final moodPoints = _validPoints(chartData['dailyMood'] ?? []);

    final doc = pw.Document();
    final generatedAt = DateFormat('MMM d, yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Text(
                'Lumora Progress Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A3A5C'),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated on $generatedAt',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blueGrey600,
                ),
              ),
              pw.SizedBox(height: 28),
              _buildChartSection(
                title: 'Anxiety Remaining (%)',
                points: anxietyPoints,
                color: PdfColors.red500,
                maxY: 100,
              ),
              pw.SizedBox(height: 28),
              _buildChartSection(
                title: 'Daily Mood (1-5 Level)',
                points: moodPoints,
                color: PdfColors.green500,
                maxY: 5,
              ),
            ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildChartSection({
    required String title,
    required List<ChartDataPoint> points,
    required PdfColor color,
    required double maxY,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: color,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A3A5C'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          if (points.isEmpty)
            pw.Container(
              height: 180,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Not enough data to display yet.',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blueGrey500,
                ),
              ),
            )
          else if (points.length == 1)
            _buildSingleValueSummary(points.first, color, maxY)
          else
            pw.SizedBox(
              height: 220,
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: _buildDateAxis(points),
                  yAxis: _buildValueAxis(maxY),
                ),
                datasets: [
                  pw.LineDataSet<pw.PointChartValue>(
                    data:
                        points
                            .asMap()
                            .entries
                            .map(
                              (entry) => pw.PointChartValue(
                                entry.key.toDouble(),
                                entry.value.y.clamp(0, maxY),
                              ),
                            )
                            .toList(),
                    color: color,
                    pointColor: color,
                    pointSize: 3,
                    lineWidth: 2,
                    drawSurface: true,
                    surfaceOpacity: 0.16,
                    isCurved: points.length > 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.GridAxis _buildDateAxis(List<ChartDataPoint> points) {
    final tickIndexes = _sampleTickIndexes(points.length);
    return pw.FixedAxis<double>(
      tickIndexes.map((index) => index.toDouble()).toList(),
      format: (value) => _dateLabel(points[value.round()].x),
      textStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600),
      divisions: false,
    );
  }

  pw.GridAxis _buildValueAxis(double maxY) {
    final step = maxY >= 100 ? 20.0 : 1.0;
    final values = <double>[];
    for (var value = 0.0; value <= maxY; value += step) {
      values.add(value);
    }
    if (values.last != maxY) values.add(maxY);

    return pw.FixedAxis<double>(
      values,
      format: (value) => value.toInt().toString(),
      textStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600),
      divisions: true,
      divisionsColor: PdfColor.fromHex('#E2E8F0'),
    );
  }

  List<int> _sampleTickIndexes(int length) {
    if (length <= 6) {
      return List<int>.generate(length, (index) => index);
    }

    final lastIndex = length - 1;
    final indexes = <int>{};
    for (var i = 0; i < 6; i++) {
      indexes.add(((lastIndex * i) / 5).round());
    }
    return indexes.toList()..sort();
  }

  String _dateLabel(double epochMilliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMilliseconds.toInt());
    return DateFormat('MM/dd').format(date);
  }

  List<ChartDataPoint> _validPoints(List<ChartDataPoint> points) {
    return points
        .where((point) => point.x.isFinite && point.y.isFinite)
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  pw.Widget _buildSingleValueSummary(
    ChartDataPoint point,
    PdfColor color,
    double maxY,
  ) {
    final value = point.y.clamp(0, maxY).toStringAsFixed(1);
    final cleanValue =
        value.endsWith('.0') ? value.substring(0, value.length - 2) : value;

    return pw.Container(
      height: 180,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            cleanValue,
            style: pw.TextStyle(
              fontSize: 30,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _dateLabel(point.x),
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.blueGrey600,
            ),
          ),
        ],
      ),
    );
  }
}
