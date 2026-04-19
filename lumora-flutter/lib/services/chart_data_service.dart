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
      final moodScore = data['moodScore'];

      if (ts != null) {
        final double epoch = ts.toDate().millisecondsSinceEpoch.toDouble();

        // Add Anxiety Point
        if (remainingPercent is num) {
          dailyAnxietyPoints.add(
            ChartDataPoint(epoch, remainingPercent.toDouble()),
          );
        }

        // Add Mood Point
        if (moodScore is num) {
          dailyMoodPoints.add(ChartDataPoint(epoch, moodScore.toDouble()));
        }
      }
    }

    // Sort both datasets chronologically
    dailyAnxietyPoints.sort((a, b) => a.x.compareTo(b.x));
    dailyMoodPoints.sort((a, b) => a.x.compareTo(b.x));

    return {'dailyAnxiety': dailyAnxietyPoints, 'dailyMood': dailyMoodPoints};
  }
}
