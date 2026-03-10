import 'package:flutter/material.dart';

class BreathingCompletionScreen extends StatefulWidget {
  final String techniqueName;
  final int roundsCompleted;
  final int totalSeconds;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  const BreathingCompletionScreen({
    super.key,
    required this.techniqueName,
    required this.roundsCompleted,
    required this.totalSeconds,
    required this.onTryAgain,
    required this.onBack,
  });

  @override
  State<BreathingCompletionScreen> createState() =>
      _BreathingCompletionScreenState();
}

class _BreathingCompletionScreenState extends State<BreathingCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int? _mood; // 0=sad, 1=neutral, 2=relaxed

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _duration {
    final m = widget.totalSeconds ~/ 60;
    final s = widget.totalSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF5BB8D4),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Session Complete',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.techniqueName,
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(label: 'Duration', value: _duration),
                    if (widget.roundsCompleted > 0) ...[
                      const SizedBox(width: 16),
                      _StatChip(
                        label: 'Rounds',
                        value: '${widget.roundsCompleted}',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 36),
                const Text(
                  'How do you feel?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MoodButton(
                      emoji: '😟',
                      selected: _mood == 0,
                      onTap: () => setState(() => _mood = 0),
                    ),
                    const SizedBox(width: 16),
                    _MoodButton(
                      emoji: '😐',
                      selected: _mood == 1,
                      onTap: () => setState(() => _mood = 1),
                    ),
                    const SizedBox(width: 16),
                    _MoodButton(
                      emoji: '😌',
                      selected: _mood == 2,
                      onTap: () => setState(() => _mood = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onTryAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BB8D4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text(
                          'Try again',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _MoodButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
          border:
              selected
                  ? Border.all(color: Colors.white60, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      ),
    );
  }
}
