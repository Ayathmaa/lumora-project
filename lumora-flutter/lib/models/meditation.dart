import 'package:cloud_firestore/cloud_firestore.dart';

enum MeditationCategory {
  quick1Min('quick_1_min', 1, '1 min'),
  fiveMin('5_min', 5, '5 min'),
  tenMin('10_min', 10, '10 min'),
  fifteenMin('15_min', 15, '15 min'),
  twentyMin('20_min', 20, '20 min');

  const MeditationCategory(
    this.firestoreValue,
    this.durationMinutes,
    this.label,
  );

  final String firestoreValue;
  final int durationMinutes;
  final String label;

  static MeditationCategory fromValue(String value) {
    return MeditationCategory.values.firstWhere(
      (category) => category.firestoreValue == value,
      orElse: () => MeditationCategory.fiveMin,
    );
  }
}

class Meditation {
  final String id;
  final String title;
  final String videoPath;
  final MeditationCategory category;
  final int durationMinutes;
  final String durationLabel;
  final int sortOrder;
  final bool isActive;
  final String description;
  final String thumbnailUrl;

  const Meditation({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.category,
    required this.durationMinutes,
    required this.durationLabel,
    required this.sortOrder,
    required this.isActive,
    required this.description,
    required this.thumbnailUrl,
  });

  factory Meditation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final category = MeditationCategory.fromValue(
      (data['category'] as String?) ??
          MeditationCategory.fiveMin.firestoreValue,
    );

    return Meditation(
      id: doc.id,
      title:
          (data['title'] as String?)?.trim().isNotEmpty == true
              ? (data['title'] as String).trim()
              : 'Meditation',
      videoPath: (data['videoPath'] as String?) ?? '',
      category: category,
      durationMinutes:
          (data['durationMinutes'] as num?)?.toInt() ??
          category.durationMinutes,
      durationLabel:
          (data['durationLabel'] as String?)?.trim().isNotEmpty == true
              ? (data['durationLabel'] as String).trim()
              : category.label,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
      description: (data['description'] as String?)?.trim() ?? '',
      thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
    );
  }
}
