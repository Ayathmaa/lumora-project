import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/progress_charts.dart';

class ChartDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<Map<String, List<ChartDataPoint>>> getChartDataStream([String? userId]) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value({'dailyAnxiety': [], 'dailyMood': []});
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_analytics')
        .snapshots()
        .map((snapshot) {
          List<ChartDataPoint> dailyAnxietyPoints = [];
          List<ChartDataPoint> dailyMoodPoints = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final ts = data['timestamp'] as Timestamp?;
            final remainingPercent = data['anxietyRemainingPercent'];
            final moodScore = data['moodScore'];

            if (ts != null) {
              final double epoch =
                  ts.toDate().millisecondsSinceEpoch.toDouble();

              if (remainingPercent is num && remainingPercent > 0) {
                dailyAnxietyPoints.add(
                  ChartDataPoint(epoch, remainingPercent.toDouble()),
                );
              }

              if (moodScore is num && moodScore > 0) {
                dailyMoodPoints.add(
                  ChartDataPoint(epoch, moodScore.toDouble()),
                );
              }
            }
          }

          dailyAnxietyPoints.sort((a, b) => a.x.compareTo(b.x));
          dailyMoodPoints.sort((a, b) => a.x.compareTo(b.x));

          return {
            'dailyAnxiety': dailyAnxietyPoints,
            'dailyMood': dailyMoodPoints,
          };
        });
  }
}
