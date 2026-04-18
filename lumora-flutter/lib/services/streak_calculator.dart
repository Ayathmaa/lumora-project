import 'package:lumora_flutter/services/progress_service.dart';

class StreakCalculator {
  static int computeStreak(List<ActivityEvent> events) {
    if (events.isEmpty) return 0;

    // Group unique date strings based on local time
    final uniqueDates =
        events
            .map((e) {
              return DateTime(e.date.year, e.date.month, e.date.day);
            })
            .toSet()
            .toList();

    uniqueDates.sort((a, b) => b.compareTo(a)); // Descending dates

    if (uniqueDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayNoon = DateTime(today.year, today.month, today.day);

    int streak = 0;
    final latest = uniqueDates.first;

    if (todayNoon.difference(latest).inDays > 1) {
      return 0; // Streak broken
    }

    streak = 1;
    for (int i = 1; i < uniqueDates.length; i++) {
      final current = uniqueDates[i - 1];
      final previous = uniqueDates[i];
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
