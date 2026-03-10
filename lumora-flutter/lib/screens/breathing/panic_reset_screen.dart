import 'package:flutter/material.dart';

import 'breathing_exercise_screen.dart';
import 'breathing_technique.dart';

class PanicResetScreen extends StatelessWidget {
  const PanicResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BreathingExerciseScreen(technique: kPanicReset);
  }
}
