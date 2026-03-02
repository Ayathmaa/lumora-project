import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);

class MindfulScreen extends StatefulWidget {
  const MindfulScreen({super.key});

  @override
  State<MindfulScreen> createState() => _MindfulScreenState();
}

class _MindfulScreenState extends State<MindfulScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;

  // Breathing exercise
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _phaseDurations = [4, 4, 6, 2]; // seconds
  int _phaseIndex = 0;
  int _phaseSeconds = 4;
  bool _breathingActive = false;
  Timer? _breathingTimer;
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  // Exercises list
  final _exercises = [
    _Exercise(
      title: '4-7-8 Breathing',
      duration: '5 min',
      icon: Icons.air_rounded,
      color: Color(0xFF6BAED4),
    ),
    _Exercise(
      title: 'Body Scan',
      duration: '10 min',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF80C9A4),
    ),
    _Exercise(
      title: 'Grounding 5-4-3-2-1',
      duration: '7 min',
      icon: Icons.landscape_rounded,
      color: Color(0xFFB89FD8),
    ),
    _Exercise(
      title: 'Loving Kindness',
      duration: '8 min',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF8C98),
    ),
    _Exercise(
      title: 'Progressive Relaxation',
      duration: '15 min',
      icon: Icons.spa_rounded,
      color: Color(0xFFFFCC55),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _toggleBreathing() {
    if (_breathingActive) {
      _breathingTimer?.cancel();
      _breathController.stop();
      setState(() {
        _breathingActive = false;
        _phaseIndex = 0;
        _phaseSeconds = _phaseDurations[0];
      });
    } else {
      setState(() {
        _breathingActive = true;
        _phaseIndex = 0;
        _phaseSeconds = _phaseDurations[0];
      });
      _runPhase();
    }
  }

  void _runPhase() {
    _updateAnimation();
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _phaseSeconds--;
        if (_phaseSeconds <= 0) {
          _phaseIndex = (_phaseIndex + 1) % _phases.length;
          _phaseSeconds = _phaseDurations[_phaseIndex];
          _updateAnimation();
        }
      });
    });
  }

  void _updateAnimation() {
    final phase = _phases[_phaseIndex];
    if (phase == 'Inhale') {
      _breathController.forward();
    } else if (phase == 'Exhale') {
      _breathController.reverse();
    }
  }

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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _kNavy,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mindful',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kNavy,
                        ),
                      ),
                      Text(
                        'Breathe, relax, and stay present',
                        style: TextStyle(fontSize: 12, color: _kSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Box breathing card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Box Breathing',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Reduces anxiety and stress',
                      style: TextStyle(fontSize: 12, color: _kSubtitle),
                    ),
                    const SizedBox(height: 28),

                    // Animated circle
                    AnimatedBuilder(
                      animation: _breathAnim,
                      builder: (_, __) {
                        return Container(
                          width: 160 * _breathAnim.value,
                          height: 160 * _breathAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kBlue.withValues(alpha: 0.15),
                            border: Border.all(color: _kBlue, width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _breathingActive
                                    ? _phases[_phaseIndex]
                                    : 'Ready',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kNavy,
                                ),
                              ),
                              if (_breathingActive) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$_phaseSeconds',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: _kBlue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: 160,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _toggleBreathing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _breathingActive ? Colors.redAccent : _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _breathingActive ? 'Stop' : 'Start',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── More exercises ────────────────────────────────────────
              const Text(
                'More Exercises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 12),
              ..._exercises.map((e) => _ExerciseCard(exercise: e)),
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

// ── Exercise card ─────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final _Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: exercise.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(exercise.icon, color: exercise.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.duration,
                  style: const TextStyle(fontSize: 12, color: _kSubtitle),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _kIconBg, shape: BoxShape.circle),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: _kBlue,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Exercise {
  final String title;
  final String duration;
  final IconData icon;
  final Color color;
  const _Exercise({
    required this.title,
    required this.duration,
    required this.icon,
    required this.color,
  });
}
