import 'package:flutter/material.dart';

import 'breathing_exercise_screen.dart';
import 'breathing_technique.dart';

class BoxBreathingScreen extends StatelessWidget {
  const BoxBreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BreathingExerciseScreen(technique: kBoxBreathing);
  }
}
