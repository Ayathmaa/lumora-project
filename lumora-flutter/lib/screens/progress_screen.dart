import 'package:flutter/material.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kIconBg = Color(0xFFD6ECFA);
const _kDotGreen = Color(0xFF4CAF50);
const _kDotOrange = Color(0xFFFFA726);
const _kDotBlue = Color(0xFF6BAED4);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _showMonthly = true;
  DateTime _currentMonth = DateTime(2024, 1);

  static const _weeklyMood = [3.5, 4.2, 3.8, 4.5, 4.0, 4.8];
  static const _weekLabels = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _monthlyMood = [2.8, 3.2, 3.8, 4.0, 4.4, 4.8];
  static const _monthLabels = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

  static const _activities = <int, List<Color>>{
    2: [_kDotGreen, _kDotOrange],
    3: [_kDotGreen],
    5: [_kDotOrange, _kDotOrange],
    7: [_kDotGreen],
    8: [_kDotGreen, _kDotOrange],
    10: [_kDotBlue],
    12: [_kDotOrange, _kDotOrange],
    14: [_kDotGreen, _kDotOrange],
    15: [_kDotGreen],
    18: [_kDotBlue],
    22: [_kDotOrange],
    25: [_kDotGreen, _kDotOrange],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildLevelCard(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildMoodOverview(),
              const SizedBox(height: 16),
              _buildJourneyCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Your Growth Journey ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Every step counts towards a calmer you.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _kBlue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level 5',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Calm Explorer',
                    style: TextStyle(fontSize: 13, color: _kSubtitle),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0EAF4),
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            iconBg: const Color(0xFFFFEDE5),
            iconColor: const Color(0xFFFF8C69),
            value: '14',
            label: 'Total Streaks',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF66BB6A),
            value: '28',
            label: 'Total Sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            iconBg: const Color(0xFFF3EAF8),
            iconColor: const Color(0xFFAB7FD4),
            value: '4.8',
            label: 'Avg Mood',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSubtitle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodOverview() {
    final data =
        _showMonthly
            ? List<double>.from(_monthlyMood)
            : List<double>.from(_weeklyMood);
    final labels = _showMonthly ? _monthLabels : _weekLabels;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Mood Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              const Spacer(),
              _buildToggle('Weekly', !_showMonthly),
              const SizedBox(width: 6),
              _buildToggle('Monthly', _showMonthly),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: _MoodChartPainter(data: data)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                labels
                    .map(
                      (l) => Text(
                        l,
                        style: const TextStyle(fontSize: 10, color: _kSubtitle),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showMonthly = label == 'Monthly'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _kSubtitle,
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your Journey',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap:
                    () => setState(
                      () =>
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                          ),
                    ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: _kNavy,
                  size: 22,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kNavy,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () => setState(
                      () =>
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                          ),
                    ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _kNavy,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children:
                ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kSubtitle,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          _buildCalendarGrid(startWeekday, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int startWeekday, int daysInMonth) {
    final rows = <Widget>[];
    int day = 1 - startWeekday;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final dots = _activities[day] ?? const [];
          final dayStr = day.toString();
          cells.add(
            Expanded(
              child: SizedBox(
                height: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kNavy,
                      ),
                    ),
                    if (dots.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            dots
                                .map(
                                  (c) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        day++;
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _MoodChartPainter extends CustomPainter {
  final List<double> data;
  _MoodChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    const minVal = 0.0;
    const maxVal = 6.0;
    final n = data.length;
    final xStep = size.width / (n - 1);

    final points = List.generate(n, (i) {
      final x = i * xStep;
      final y =
          size.height - ((data[i] - minVal) / (maxVal - minVal)) * size.height;
      return Offset(x, y);
    });

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < n - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    final fillPath =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6BAED4).withValues(alpha: 0.35),
              const Color(0xFF6BAED4).withValues(alpha: 0.03),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint =
        Paint()
          ..color = const Color(0xFF6BAED4)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_MoodChartPainter old) => old.data != data;
}
