import 'package:flutter/material.dart';

import 'breathing_exercise_screen.dart';
import 'breathing_technique.dart';

class SlowDeepBreathingScreen extends StatelessWidget {
  const SlowDeepBreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BreathingExerciseScreen(technique: kSlowDeepBreathing);
  }
}
