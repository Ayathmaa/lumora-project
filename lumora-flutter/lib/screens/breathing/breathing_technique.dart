import 'package:flutter/material.dart';

enum BreathingPhaseType { inhale, hold, exhale }

class BreathingPhase {
  final String label;
  final int durationSeconds;
  final BreathingPhaseType type;

  const BreathingPhase({
    required this.label,
    required this.durationSeconds,
    required this.type,
  });
}

class BreathingTechnique {
  final String name;
  final List<BreathingPhase> phases;
  final int totalRounds; // 0 = time-based
  final int? sessionMinutes; // for time-based sessions
  final Color phaseColorInhale;
  final Color phaseColorHold;
  final Color phaseColorExhale;
  final bool isBoxStyle; // draws square arc vs circular arc
  final bool isPanicReset;
  final bool isSlowDeep;
  final List<String> Function(int round)? roundMessage;

  const BreathingTechnique({
    required this.name,
    required this.phases,
    required this.totalRounds,
    this.sessionMinutes,
    this.phaseColorInhale = const Color(0xFF5BB8D4),
    this.phaseColorHold = const Color(0xFF3A7CA5),
    this.phaseColorExhale = const Color(0xFF6A9EB5),
    this.isBoxStyle = false,
    this.isPanicReset = false,
    this.isSlowDeep = false,
    this.roundMessage,
  });

  int get roundDurationSeconds =>
      phases.fold(0, (sum, p) => sum + p.durationSeconds);
}

// ── Preset techniques ──────────────────────────────────────────────────────

final kBoxBreathing = BreathingTechnique(
  name: '4-4-4-4 Box Breathing',
  phases: const [
    BreathingPhase(
      label: 'Inhale',
      durationSeconds: 4,
      type: BreathingPhaseType.inhale,
    ),
    BreathingPhase(
      label: 'Hold',
      durationSeconds: 4,
      type: BreathingPhaseType.hold,
    ),
    BreathingPhase(
      label: 'Exhale',
      durationSeconds: 4,
      type: BreathingPhaseType.exhale,
    ),
    BreathingPhase(
      label: 'Hold',
      durationSeconds: 4,
      type: BreathingPhaseType.hold,
    ),
  ],
  totalRounds: 8,
  isBoxStyle: true,
);

final k478Relaxation = BreathingTechnique(
  name: '4-7-8 Relaxation',
  phases: const [
    BreathingPhase(
      label: 'Inhale',
      durationSeconds: 4,
      type: BreathingPhaseType.inhale,
    ),
    BreathingPhase(
      label: 'Hold',
      durationSeconds: 7,
      type: BreathingPhaseType.hold,
    ),
    BreathingPhase(
      label: 'Exhale slowly',
      durationSeconds: 8,
      type: BreathingPhaseType.exhale,
    ),
  ],
  totalRounds: 4,
);

final kSlowDeepBreathing = BreathingTechnique(
  name: 'Slow Deep Breathing',
  phases: const [
    BreathingPhase(
      label: 'Breathe In',
      durationSeconds: 5,
      type: BreathingPhaseType.inhale,
    ),
    BreathingPhase(
      label: 'Breathe Out',
      durationSeconds: 5,
      type: BreathingPhaseType.exhale,
    ),
  ],
  totalRounds: 0,
  sessionMinutes: 5,
  isSlowDeep: true,
);

final kPanicReset = BreathingTechnique(
  name: 'Panic Reset Breath',
  phases: const [
    BreathingPhase(
      label: 'Inhale',
      durationSeconds: 2,
      type: BreathingPhaseType.inhale,
    ),
    BreathingPhase(
      label: 'Exhale slowly...',
      durationSeconds: 6,
      type: BreathingPhaseType.exhale,
    ),
  ],
  totalRounds: 6,
  phaseColorInhale: Color(0xFF5B9ED4),
  phaseColorExhale: Color(0xFF4ABFBF),
  isPanicReset: true,
);
