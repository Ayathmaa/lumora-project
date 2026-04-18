import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationStats {
  final int xp;
  final int currentStreak;
  final int highestStreak;

  const GamificationStats({
    this.xp = 0,
    this.currentStreak = 0,
    this.highestStreak = 0,
  });

  factory GamificationStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GamificationStats();
    return GamificationStats(
      xp: data['xp'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      highestStreak: data['highestStreak'] as int? ?? 0,
    );
  }
}

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<GamificationStats> getStatsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const GamificationStats());
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('user_stats')
        .doc('gamification')
        .snapshots()
        .map((snap) => GamificationStats.fromMap(snap.data()));
  }
}
