import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/progress_charts.dart';

class ChartDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, List<ChartDataPoint>>> fetchChartData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {'dailyAnxiety': [], 'dailyMood': []};
    }

    List<ChartDataPoint> dailyAnxietyPoints = [];
    List<ChartDataPoint> dailyMoodPoints = [];

    // 1. Directly fetch pre-aggregated Daily Analytics from our optimized Cloud Function setup!
    // This turns potentially thousands of reads per user into just a couple of documents!
    final analyticsDocs =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_analytics')
            .get();

    for (var doc in analyticsDocs.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      final remainingPercent = data['anxietyRemainingPercent'];

      if (ts != null && remainingPercent is num) {
        dailyAnxietyPoints.add(
          ChartDataPoint(
            ts.toDate().millisecondsSinceEpoch.toDouble(),
            remainingPercent.toDouble(),
          ),
        );
      }
    }
    dailyAnxietyPoints.sort((a, b) => a.x.compareTo(b.x));

    // 2. Fetch Daily Moods
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
        if (d != null) {
          final midnight = DateTime(d.year, d.month, d.day);
          final score = doc.data()['score'];
          if (score is num) {
            dailyMoodPoints.add(
              ChartDataPoint(
                midnight.millisecondsSinceEpoch.toDouble(),
                score.toDouble(),
              ),
            );
          }
        }
      }
    }
    dailyMoodPoints.sort((a, b) => a.x.compareTo(b.x));

    return {'dailyAnxiety': dailyAnxietyPoints, 'dailyMood': dailyMoodPoints};
  }
}
