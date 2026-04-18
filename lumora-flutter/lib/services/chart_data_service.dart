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

    // Daily aggregations
    Map<String, Map<String, dynamic>> dailyAnxietyMap = {};

    // 1. Fetch Journals
    final journals =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cbt_journal')
            .orderBy('createdAt')
            .get();

    for (var doc in journals.docs) {
      final data = doc.data();
      final pre = data['preAnxietyLevel'];
      final post = data['postAnxietyLevel'];
      if (pre is num && post is num) {
        double preVal = pre.toDouble();
        double postVal = post.toDouble();
        
        // As defined: percentage = (reduction / pre) * 100
        // Because anxiety is a bad thing, we invert it so the chart *decreases* when reduction is high
        // Remaining Anxiety = 100 - Reduction = (post / pre) * 100.
        // If pre is 0, we can safely assume 0 anxiety remained.
        double percentage = preVal > 0 ? (postVal / preVal) * 100.0 : 0.0;

        final ts = data['createdAt'] as Timestamp?;
        if (ts != null) {
          final date = ts.toDate();
          final midnight = DateTime(date.year, date.month, date.day);
          final dKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          dailyAnxietyMap.putIfAbsent(
            dKey,
            () => {
              'sum': 0.0,
              'count': 0,
              'ts': midnight.millisecondsSinceEpoch.toDouble(),
            },
          );
          dailyAnxietyMap[dKey]!['sum'] += percentage;
          dailyAnxietyMap[dKey]!['count'] += 1;
        }
      }
    }

    // 2. Fetch ERP
    final erps =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('erp_sessions')
            .orderBy('timestamp')
            .get();

    for (var doc in erps.docs) {
      final data = doc.data();
      final isComplete =
          data['session_complete'] == 1; // Assuming 1 means complete
      if (isComplete) {
        final pre = data['pre_anxiety'];
        final post = data['post_anxiety'];
        if (pre is num && post is num) {
          double preVal = pre.toDouble();
          double postVal = post.toDouble();
          
          double percentage = preVal > 0 ? (postVal / preVal) * 100.0 : 0.0;

          final ts = data['timestamp'] as Timestamp?;
          if (ts != null) {
            final date = ts.toDate();
            final midnight = DateTime(date.year, date.month, date.day);
            final dKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            dailyAnxietyMap.putIfAbsent(
              dKey,
              () => {
                'sum': 0.0,
                'count': 0,
                'ts': midnight.millisecondsSinceEpoch.toDouble(),
              },
            );
            dailyAnxietyMap[dKey]!['sum'] += percentage;
            dailyAnxietyMap[dKey]!['count'] += 1;
          }
        }
      }
    }

    // 3. Process Daily Anxiety
    final sortedKeys = dailyAnxietyMap.keys.toList()..sort();
    for (var key in sortedKeys) {
      final map = dailyAnxietyMap[key]!;
      if (map['count'] > 0) {
        dailyAnxietyPoints.add(
          ChartDataPoint(map['ts'], map['sum'] / map['count']),
        );
      }
    }
    dailyAnxietyPoints.sort(
      (a, b) => a.x.compareTo(b.x),
    ); // Guarantee clean chronological line

    // 4. Fetch Daily Moods
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
