import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityEvent {
  final DateTime date;
  final String type;
  final String title;
  final String detail;

  ActivityEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.detail,
  });
}

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ActivityEvent>> fetchAllActivities([String? userId]) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('timeline_events')
              .orderBy('date', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final ts = data['date'] as Timestamp?;
        return ActivityEvent(
          date: ts != null ? ts.toDate() : DateTime.now(),
          type: data['type'] as String? ?? 'Unknown',
          title: data['title'] as String? ?? '',
          detail: data['detail'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
