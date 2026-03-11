import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Returns true if the user has already logged a mood today.
  Future<bool> hasTodayMood() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_moods')
            .doc(_todayKey())
            .get();
    return doc.exists;
  }

  // score: 1 (worst) → 5 (best). Uses set() so re-logging the same day
  // overwrites rather than duplicating.
  Future<void> saveTodayMood({required int score}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in.');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_moods')
        .doc(_todayKey())
        .set({'score': score, 'loggedAt': FieldValue.serverTimestamp()});
  }
}
