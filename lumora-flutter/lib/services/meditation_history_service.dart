import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/meditation.dart';

class MeditationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<String?> startSession(
    Meditation meditation, {
    required int positionSeconds,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    final ref =
        _firestore
            .collection('users')
            .doc(uid)
            .collection('meditation_history')
            .doc();

    await ref.set({
      'meditationId': meditation.id,
      'titleSnapshot': meditation.title,
      'youtubeVideoId': meditation.youtubeVideoId,
      'category': meditation.category.firestoreValue,
      'durationMinutes': meditation.durationMinutes,
      'startedAt': FieldValue.serverTimestamp(),
      'lastPositionSeconds': positionSeconds,
      'completed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> updateSession({
    required String sessionId,
    required int positionSeconds,
    required bool completed,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meditation_history')
        .doc(sessionId)
        .set({
          'lastPositionSeconds': positionSeconds,
          'completed': completed,
          'completedAt': completed ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
