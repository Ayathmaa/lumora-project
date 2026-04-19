import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationStats {
  final int xp;
  final int currentStreak;
  final int highestStreak;
  final int journalStreak;
  final int erpStreak;
  final int breathingStreak;
  final int habitStreak;

  const GamificationStats({
    this.xp = 0,
    this.currentStreak = 0,
    this.highestStreak = 0,
    this.journalStreak = 0,
    this.erpStreak = 0,
    this.breathingStreak = 0,
    this.habitStreak = 0,
  });

  factory GamificationStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GamificationStats();

    final modStreaks = data['moduleStreaks'] as Map<String, dynamic>? ?? {};

    return GamificationStats(
      xp: data['xp'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      highestStreak: data['highestStreak'] as int? ?? 0,
      journalStreak: modStreaks['journal'] as int? ?? 0,
      erpStreak: modStreaks['erp'] as int? ?? 0,
      breathingStreak: modStreaks['breathing'] as int? ?? 0,
      habitStreak: modStreaks['habit'] as int? ?? 0,
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
