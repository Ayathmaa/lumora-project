import 'package:flutter/material.dart';

class BreathingSessionControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final bool showEmergencyExit;
  final VoidCallback? onEmergencyExit;

  const BreathingSessionControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onStop,
    this.showEmergencyExit = false,
    this.onEmergencyExit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isRunning)
              _ControlButton(
                icon: Icons.play_arrow_rounded,
                label: 'Start',
                onTap: onStart,
                primary: true,
              )
            else ...[
              _ControlButton(
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: isPaused ? 'Resume' : 'Pause',
                onTap: onPause,
                primary: true,
              ),
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                onTap: onStop,
                primary: false,
              ),
            ],
          ],
        ),
        if (showEmergencyExit && isRunning) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: onEmergencyExit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              minimumSize: const Size(48, 48),
            ),
            child: const Text(
              "I'm okay now",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color:
              primary
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white38, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
