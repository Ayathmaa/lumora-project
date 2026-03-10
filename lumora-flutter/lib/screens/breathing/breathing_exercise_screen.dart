import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'breathing_circle.dart';
import 'breathing_technique.dart';
import 'completion_screen.dart';
import 'session_controls.dart';

// ── Box-breathing tip messages ──────────────────────────────────────────────
const _boxTips = [
  'Breathe in slowly through your nose',
  'Breathe in slowly through your nose',
  'Feel your chest and belly expand',
  'Feel your chest and belly expand',
  'Let your shoulders drop',
  'Let your shoulders drop',
  'Let your shoulders drop',
  'Let your shoulders drop',
];

const _slowDeepAffirmations = [
  'Let your body relax with each breath',
  'Let your body relax with each breath',
  'Let your body relax with each breath',
  'Let your body relax with each breath',
  'Let your body relax with each breath',
  "You're doing great",
  "You're doing great",
  "You're doing great",
  "You're doing great",
  "You're doing great",
  'Feel the tension leaving your body',
];

const _panicMessages = [
  "You're safe. Let's slow this down.",
  'Good. Keep following the circle.',
  'Your body is calming down.',
  "You're doing really well.",
  'Almost there. Stay with it.',
  'Well done. You did it.',
];

class BreathingExerciseScreen extends StatefulWidget {
  final BreathingTechnique technique;

  const BreathingExerciseScreen({super.key, required this.technique});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  // ── Session state ─────────────────────────────────────────────────────────
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isComplete = false;
  int _currentPhaseIndex = 0;
  int _currentRound = 0; // 0-based
  int _countdown = 0;
  int _elapsedSeconds = 0;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _circleCtrl;
  late Animation<double> _circleSize;
  late AnimationController _pulseCtrl; // hold pulse / glow pulse
  late Animation<double> _pulseAnim;

  // ── Ripple (slow deep) ────────────────────────────────────────────────────
  AnimationController? _rippleCtrl;
  final List<double> _rippleScales = [];

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _sessionTimer;

  // ── Session tracking ──────────────────────────────────────────────────────

  // ── Slow deep: time-based ─────────────────────────────────────────────────
  int _sessionSecondsRemaining = 0;

  BreathingTechnique get _t => widget.technique;
  BreathingPhase get _phase => _t.phases[_currentPhaseIndex];

  Color get _phaseColor {
    switch (_phase.type) {
      case BreathingPhaseType.inhale:
        // Panic reset gradually shifts color over rounds
        if (_t.isPanicReset) {
          final fraction = _currentRound / (_t.totalRounds - 1).clamp(1, 999);
          return Color.lerp(
            _t.phaseColorInhale,
            _t.phaseColorExhale,
            fraction,
          )!;
        }
        return _t.phaseColorInhale;
      case BreathingPhaseType.hold:
        return _t.phaseColorHold;
      case BreathingPhaseType.exhale:
        return _t.phaseColorExhale;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _t.phases.first.durationSeconds),
    );
    _circleSize = Tween<double>(
      begin: kCircleMin,
      end: kCircleMin,
    ).animate(_circleCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: -4,
      end: 4,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    if (_t.isSlowDeep) {
      _rippleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      );
    }

    if (_t.sessionMinutes != null) {
      _sessionSecondsRemaining = _t.sessionMinutes! * 60;
    }
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _pulseCtrl.dispose();
    _rippleCtrl?.dispose();
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  void _start() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _currentPhaseIndex = 0;
      _currentRound = 0;
      _elapsedSeconds = 0;
      if (_t.sessionMinutes != null) {
        _sessionSecondsRemaining = _t.sessionMinutes! * 60;
      }
    });
    _startSessionTimer();
    _beginPhase();
  }

  void _pause() {
    if (_isPaused) {
      // Resume
      setState(() => _isPaused = false);
      _circleCtrl.forward();
      _restartCountdownTimer();
      _sessionTimer?.cancel();
      _startSessionTimer();
    } else {
      // Pause
      setState(() => _isPaused = true);
      _circleCtrl.stop();
      _countdownTimer?.cancel();
      _sessionTimer?.cancel();
    }
  }

  void _stop() {
    _cleanup();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isComplete = false;
      _currentPhaseIndex = 0;
      _currentRound = 0;
    });
  }

  void _cleanup() {
    _circleCtrl.stop();
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _rippleCtrl?.stop();
  }

  void _complete() {
    _cleanup();
    setState(() {
      _isComplete = true;
      _isRunning = false;
    });
  }

  void _tryAgain() {
    setState(() {
      _isComplete = false;
      _elapsedSeconds = 0;
    });
    _start();
  }

  // ── Phase logic ───────────────────────────────────────────────────────────
  void _beginPhase() {
    final phase = _t.phases[_currentPhaseIndex];
    final dur = Duration(seconds: phase.durationSeconds);

    // Determine circle animation direction
    final toSize =
        phase.type == BreathingPhaseType.exhale ? kCircleMin : kCircleMax;
    final fromSize =
        phase.type == BreathingPhaseType.exhale ? kCircleMax : kCircleMin;

    Curve curve;
    if (phase.type == BreathingPhaseType.inhale) {
      curve = _t.isPanicReset ? Curves.easeIn : Curves.easeInOut;
    } else if (phase.type == BreathingPhaseType.exhale) {
      curve = Curves.easeOut;
    } else {
      curve = Curves.linear;
    }

    _circleCtrl.duration = dur;
    _circleCtrl.stop();
    _circleCtrl.value = 0;

    if (phase.type == BreathingPhaseType.hold) {
      // Freeze circle at held size — just pulse
      final holdSize = _currentPhaseIndex == 1 ? kCircleMax : kCircleMin;
      _circleSize = Tween<double>(
        begin: holdSize,
        end: holdSize,
      ).animate(_circleCtrl);
    } else {
      _circleSize = Tween<double>(
        begin: fromSize,
        end: toSize,
      ).animate(CurvedAnimation(parent: _circleCtrl, curve: curve));
    }

    // Start ripple on inhale (slow deep)
    if (_t.isSlowDeep && phase.type == BreathingPhaseType.inhale) {
      _startRipple();
    }

    _circleCtrl.forward();

    setState(() => _countdown = phase.durationSeconds);
    _restartCountdownTimer();

    // Listen for phase end
    _circleCtrl.addStatusListener(_onPhaseEnd);
  }

  void _onPhaseEnd(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _circleCtrl.removeStatusListener(_onPhaseEnd);
    if (!_isRunning || _isPaused) return;

    final nextPhaseIndex = (_currentPhaseIndex + 1) % _t.phases.length;
    final isNewRound = nextPhaseIndex == 0;

    if (isNewRound) {
      final nextRound = _currentRound + 1;
      // Round-based completion
      if (_t.totalRounds > 0 && nextRound >= _t.totalRounds) {
        _complete();
        return;
      }
      setState(() {
        _currentRound = nextRound;
        _currentPhaseIndex = 0;
      });
    } else {
      setState(() => _currentPhaseIndex = nextPhaseIndex);
    }

    _beginPhase();
  }

  void _restartCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
      // Screen reader announcement
      SemanticsService.announce(
        '${_phase.label}, $_countdown',
        TextDirection.ltr,
      );
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
        if (_t.sessionMinutes != null) {
          _sessionSecondsRemaining = (_t.sessionMinutes! * 60 - _elapsedSeconds)
              .clamp(0, 9999);
          if (_sessionSecondsRemaining == 0) {
            t.cancel();
            _complete();
          }
        }
      });
    });
  }

  void _startRipple() {
    _rippleCtrl?.reset();
    _rippleCtrl?.forward();
    setState(() {
      _rippleScales.clear();
      _rippleScales.addAll([0.0, 0.3]);
    });
    _rippleCtrl?.addListener(() {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _rippleScales.length; i++) {
          _rippleScales[i] = (_rippleScales[i] + 0.008).clamp(0.0, 1.0);
        }
      });
    });
  }

  // ── Progress ──────────────────────────────────────────────────────────────
  double get _roundProgress {
    final roundTotal = _t.roundDurationSeconds;
    final elapsed = _t.phases
        .take(_currentPhaseIndex)
        .fold(0, (s, p) => s + p.durationSeconds);
    final phaseElapsed = _phase.durationSeconds - _countdown;
    return (elapsed + phaseElapsed) / roundTotal;
  }

  double get _sessionProgress {
    if (_t.sessionMinutes != null) {
      return _elapsedSeconds / (_t.sessionMinutes! * 60);
    }
    final total = _t.totalRounds * _t.roundDurationSeconds;
    return total == 0 ? 0 : _elapsedSeconds / total;
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  String get _roundLabel {
    if (_t.isSlowDeep) return _formatTime(_sessionSecondsRemaining);
    return 'Round ${_currentRound + 1} of ${_t.totalRounds}';
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _instructionText {
    if (_t.isPanicReset) {
      final idx = _currentRound.clamp(0, _panicMessages.length - 1);
      return _panicMessages[idx];
    }
    if (_t.isSlowDeep) {
      final cycleIdx = (_currentRound ~/ 5).clamp(
        0,
        _slowDeepAffirmations.length - 1,
      );
      return _slowDeepAffirmations[cycleIdx];
    }
    if (_t.isBoxStyle) {
      return _boxTips[_currentRound.clamp(0, _boxTips.length - 1)];
    }
    // 4-7-8
    switch (_phase.type) {
      case BreathingPhaseType.inhale:
        return 'Breathe in through your nose';
      case BreathingPhaseType.hold:
        return "Hold gently — don't strain";
      case BreathingPhaseType.exhale:
        return 'Exhale fully through your mouth';
    }
  }

  Color get _bgColor {
    if (_t.isSlowDeep) {
      return _phase.type == BreathingPhaseType.inhale
          ? const Color(0xFFD6EAF8)
          : const Color(0xFFEBF5FB);
    }
    return const Color(0xFF1A3A5C);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return BreathingCompletionScreen(
        techniqueName: _t.name,
        roundsCompleted: _currentRound,
        totalSeconds: _elapsedSeconds,
        onTryAgain: _tryAgain,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    final disableAnim = MediaQuery.of(context).disableAnimations;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 4000),
      color: _bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _t.isSlowDeep ? const Color(0xFF1A3A5C) : Colors.white,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            _t.name,
            style: TextStyle(
              color: _t.isSlowDeep ? const Color(0xFF1A3A5C) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _roundLabel,
                  style: TextStyle(
                    color:
                        _t.isSlowDeep
                            ? const Color(0xFF4A6FA5)
                            : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ── Progress arc ──────────────────────────────────────────────
              if (_isRunning)
                SizedBox(
                  width: kCircleMax + 60,
                  height: kCircleMax + 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Arc painter
                      CustomPaint(
                        size: Size(kCircleMax + 60, kCircleMax + 60),
                        painter:
                            _t.isBoxStyle
                                ? BoxProgressPainter(
                                  progress: _roundProgress,
                                  color: _phaseColor,
                                )
                                : CircularProgressPainter(
                                  progress: _roundProgress,
                                  color: _phaseColor,
                                ),
                      ),
                      // Animated circle
                      AnimatedBuilder(
                        animation: _circleCtrl,
                        builder: (_, __) {
                          final baseSize = _circleSize.value;
                          final pulseOffset =
                              _phase.type == BreathingPhaseType.hold &&
                                      !disableAnim
                                  ? _pulseAnim.value
                                  : 0.0;
                          final glowRadius =
                              _t.phases.length >= 3 &&
                                      _currentPhaseIndex == 1 &&
                                      _phase.type == BreathingPhaseType.hold &&
                                      !disableAnim
                                  ? 8.0 +
                                      (_pulseAnim.value + 4) /
                                          8.0 *
                                          12.0 // 8→20
                                  : 0.0;

                          return disableAnim
                              ? BreathingCircle(
                                size:
                                    _phase.type == BreathingPhaseType.exhale
                                        ? kCircleMin
                                        : kCircleMax,
                                color: _phaseColor,
                                phaseLabel: _phase.label,
                                countdown: _countdown,
                                bigCountdown:
                                    _phase.type == BreathingPhaseType.hold &&
                                    _phase.durationSeconds >= 7,
                                phaseType: _phase.type,
                              )
                              : BreathingCircle(
                                size: baseSize + pulseOffset,
                                color: _phaseColor,
                                phaseLabel: _phase.label,
                                countdown: _countdown,
                                bigCountdown:
                                    _phase.type == BreathingPhaseType.hold &&
                                    _phase.durationSeconds >= 7,
                                glowRadius: glowRadius,
                                rippleScales:
                                    _t.isSlowDeep
                                        ? List.unmodifiable(_rippleScales)
                                        : const [],
                                phaseType: _phase.type,
                              );
                        },
                      ),
                    ],
                  ),
                )
              else
                _buildIdleCircle(),

              const SizedBox(height: 20),

              // ── Instruction text ──────────────────────────────────────────
              if (_isRunning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _instructionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _t.isSlowDeep
                              ? const Color(0xFF4A6FA5)
                              : Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),

              const Spacer(),

              // ── Pause overlay ─────────────────────────────────────────────
              if (_isPaused)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Paused',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Controls ──────────────────────────────────────────────────
              BreathingSessionControls(
                isRunning: _isRunning,
                isPaused: _isPaused,
                onStart: _start,
                onPause: _pause,
                onStop: _stop,
                showEmergencyExit: _t.isPanicReset,
                onEmergencyExit: _complete,
              ),

              const SizedBox(height: 32),

              // ── Session progress bar ──────────────────────────────────────
              if (_isRunning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _sessionProgress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleCircle() {
    return Container(
      width: kCircleMax,
      height: kCircleMax,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _t.phaseColorInhale.withValues(alpha: 0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.air_rounded, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            _t.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap Start when ready',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
