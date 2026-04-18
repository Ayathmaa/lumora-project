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

  Future<List<ActivityEvent>> fetchAllActivities() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final List<ActivityEvent> allEvents = [];

    // 1. Fetch Journals
    final journals =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cbt_journal')
            .get();
    for (var doc in journals.docs) {
      final data = doc.data();
      final ts = data['createdAt'] as Timestamp?;
      if (ts != null) {
        final preAnx = data['preAnxietyLevel'] ?? '?';
        final postAnx = data['postAnxietyLevel'] ?? '?';
        allEvents.add(
          ActivityEvent(
            date: ts.toDate(),
            type: 'Journal',
            title: 'Journal Entry #${data['journalNumber'] ?? '?'}',
            detail: 'Pre-anxiety: $preAnx/10 | Post-anxiety: $postAnx/10',
          ),
        );
      }
    }

    // 2. Fetch ERP
    final erps =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('erp_sessions')
            .get();
    for (var doc in erps.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      if (ts != null) {
        allEvents.add(
          ActivityEvent(
            date: ts.toDate(),
            type: 'ERP',
            title: 'ERP Session',
            detail:
                '${data['duration_mins'] ?? 0} mins ${(data['session_complete'] == 1) ? '(Complete)' : '(Incomplete)'}',
          ),
        );
      }
    }

    // 3. Fetch Breathing
    final breathings =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('breathing_sessions')
            .get();
    for (var doc in breathings.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      if (ts != null) {
        allEvents.add(
          ActivityEvent(
            date: ts.toDate(),
            type: 'Breathing',
            title: 'Breathing: ${data['exerciseType'] ?? 'Exercise'}',
            detail: '${data['durationSeconds'] ?? 0} secs',
          ),
        );
      }
    }

    // 4. Fetch Habit Tracker markings
    final habits =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('habit_trackers')
            .get();
    for (var doc in habits.docs) {
      final data = doc.data();
      final habitName = data['name'] ?? 'Habit';
      final markedDates = List<String>.from(data['markedDates'] ?? []);
      for (final dateStr in markedDates) {
        try {
          // dateStr is like "2024-05-12"
          final d = DateTime.parse(dateStr);
          allEvents.add(
            ActivityEvent(
              date: DateTime(
                d.year,
                d.month,
                d.day,
                12,
                0,
              ), // Use noon implicitly
              type: 'Habit',
              title: 'Habit Kept Free',
              detail: habitName,
            ),
          );
        } catch (e) {}
      }
    }

    allEvents.sort((a, b) => b.date.compareTo(a.date)); // descending
    return allEvents;
  }
}
