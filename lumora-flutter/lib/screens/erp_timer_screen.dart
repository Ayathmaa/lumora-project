import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

const _kBg       = Color(0xFFC8DCF0);
const _kNavy     = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg   = Colors.white;
const _kIconBg   = Color(0xFFD6ECFA);
const _kBlue     = Color(0xFF6BAED4);

class ErpTimerScreen extends StatefulWidget {
  const ErpTimerScreen({super.key});

  @override
  State<ErpTimerScreen> createState() => _ErpTimerScreenState();
}

class _ErpTimerScreenState extends State<ErpTimerScreen> {
  int _navIndex = 0;

  // Timer state
  static const _presetMinutes = [5, 10, 15, 20, 30, 45];
  int _selectedMinutes = 10;
  int _secondsRemaining = 10 * 60;
  bool _isRunning = false;
  bool _isPaused  = false;
  Timer? _timer;

  // Anxiety tracking
  int _anxietyLevel = 5;
  final List<_AnxietyPoint> _log = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _secondsRemaining = minutes * 60;
    });
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isPaused  = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused  = false;
        });
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resume() {
    setState(() => _isPaused = false);
    _start();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused  = false;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  void _logAnxiety() {
    setState(() {
      _log.insert(
        0,
        _AnxietyPoint(
          level: _anxietyLevel,
          time: TimeOfDay.now().format(context),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anxiety level $_anxietyLevel/10 logged'),
        backgroundColor: _kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _timeDisplay {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      1 - (_secondsRemaining / (_selectedMinutes * 60));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _kNavy, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ERP Timer',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _kNavy)),
                      Text('Exposure & Response Prevention',
                          style: TextStyle(fontSize: 12, color: _kSubtitle)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Timer circle card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Arc progress
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 10,
                              backgroundColor: _kIconBg,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_kBlue),
                            ),
                          ),
                          Text(
                            _timeDisplay,
                            style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: _kNavy,
                                letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset
                        _CircleBtn(
                          icon: Icons.refresh_rounded,
                          onTap: _reset,
                          bg: _kIconBg,
                          fg: _kBlue,
                        ),
                        const SizedBox(width: 20),
                        // Play / Pause
                        _CircleBtn(
                          icon: _isRunning && !_isPaused
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _isRunning && !_isPaused
                              ? _pause
                              : (_isPaused ? _resume : _start),
                          bg: _kBlue,
                          fg: Colors.white,
                          size: 64,
                          iconSize: 30,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Duration presets ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kNavy)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetMinutes.map((m) {
                        final active = m == _selectedMinutes;
                        return GestureDetector(
                          onTap: () => _selectPreset(m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? _kBlue : _kIconBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${m}m',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : _kBlue)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Anxiety tracker ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Anxiety Level',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kNavy)),
                    const SizedBox(height: 4),
                    Text('Current: $_anxietyLevel / 10',
                        style: const TextStyle(
                            fontSize: 12, color: _kSubtitle)),
                    Slider(
                      value: _anxietyLevel.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _kBlue,
                      inactiveColor: _kIconBg,
                      onChanged: (v) =>
                          setState(() => _anxietyLevel = v.round()),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _logAnxiety,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Log Anxiety Level',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),

                    // Mini log
                    if (_log.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFE8F0F8)),
                      const SizedBox(height: 8),
                      ..._log.take(3).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _kIconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${p.level}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _kBlue)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Level ${p.level}/10 at ${p.time}',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSubtitle)),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LumoraNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
    this.size = 52,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: iconSize),
      ),
    );
  }
}

class _AnxietyPoint {
  final int level;
  final String time;
  const _AnxietyPoint({required this.level, required this.time});
}
