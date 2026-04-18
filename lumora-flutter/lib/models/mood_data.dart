class DailyMoodSummary {
  final DateTime date;
  final double? avgPreAnxiety; // mapped to 1-10
  final double? avgPostAnxiety; // mapped to 1-10
  final double? dailyMood; // 1-5 (5 is best)

  DailyMoodSummary({
    required this.date,
    this.avgPreAnxiety,
    this.avgPostAnxiety,
    this.dailyMood,
  });
}
