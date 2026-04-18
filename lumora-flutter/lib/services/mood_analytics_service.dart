import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_data.dart';

class MoodAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DailyMoodSummary>> fetchMoodAnalytics(
    DateTime start,
    DateTime end,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    // Map: 'yyyy-MM-dd' -> { 'preSum': 0, 'preCount': 0, ... }
    final Map<String, Map<String, dynamic>> dailyMap = {};

    String dKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    void ensureKey(String key) {
      if (!dailyMap.containsKey(key)) {
        dailyMap[key] = {
          'preSum': 0,
          'preCount': 0,
          'postSum': 0,
          'postCount': 0,
          'dailyMood': null,
          'date': null,
        };
      }
    }

    // 1. Fetch Journals
    final journals =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cbt_journal')
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end)
            .get();

    for (var doc in journals.docs) {
      final ts = doc.data()['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final key = dKey(date);
      ensureKey(key);
      dailyMap[key]!['date'] = date;

      final pre = doc.data()['preAnxietyLevel'];
      final post = doc.data()['postAnxietyLevel'];
      if (pre is num) {
        dailyMap[key]!['preSum'] += pre;
        dailyMap[key]!['preCount'] += 1;
      }
      if (post is num) {
        dailyMap[key]!['postSum'] += post;
        dailyMap[key]!['postCount'] += 1;
      }
    }

    // 2. Fetch ERP
    final erps =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('erp_sessions')
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThanOrEqualTo: end)
            .get();

    for (var doc in erps.docs) {
      final ts = doc.data()['timestamp'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final key = dKey(date);
      ensureKey(key);
      dailyMap[key]!['date'] = date;

      final pre = doc.data()['pre_anxiety'];
      final post = doc.data()['post_anxiety'];
      if (pre is num) {
        dailyMap[key]!['preSum'] += pre;
        dailyMap[key]!['preCount'] += 1;
      }
      if (post is num) {
        dailyMap[key]!['postSum'] += post;
        dailyMap[key]!['postCount'] += 1;
      }
    }

    // 3. Fetch Daily Mood (id is yyyy-DD-MM which is string)
    // For daily moods, since the document ID is the date string, we need to iterate dates or fetch all.
    // To be safe and quick, fetch all daily moods and filter in memory since it's small.
    final moods =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_moods')
            .get();

    for (var doc in moods.docs) {
      final key = doc.id; // 'yyyy-MM-dd'
      if (key.length == 10) {
        final d = DateTime.tryParse(key);
        if (d != null &&
            d.isAfter(start.subtract(const Duration(days: 1))) &&
            d.isBefore(end.add(const Duration(days: 1)))) {
          ensureKey(key);
          dailyMap[key]!['date'] = dailyMap[key]!['date'] ?? d;
          dailyMap[key]!['dailyMood'] =
              (doc.data()['score'] as num?)?.toDouble();
        }
      }
    }

    final List<DailyMoodSummary> result = [];
    dailyMap.forEach((key, map) {
      if (map['date'] == null) {
        final parts = key.split('-');
        map['date'] = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      result.add(
        DailyMoodSummary(
          date: map['date'] as DateTime,
          avgPreAnxiety:
              map['preCount'] > 0 ? map['preSum'] / map['preCount'] : null,
          avgPostAnxiety:
              map['postCount'] > 0 ? map['postSum'] / map['postCount'] : null,
          dailyMood: map['dailyMood'] as double?,
        ),
      );
    });

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
