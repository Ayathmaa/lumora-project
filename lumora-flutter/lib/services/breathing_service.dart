import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BreathingSession {
  final String exerciseType;
  final int completed; // 1 = complete, 0 = incomplete
  final int durationSeconds;
  final DateTime timestamp;

  const BreathingSession({
    required this.exerciseType,
    required this.completed,
    required this.durationSeconds,
    required this.timestamp,
  });

  factory BreathingSession._fromMap(Map<String, dynamic> data) {
    final ts = data['timestamp'] as Timestamp?;
    return BreathingSession(
      exerciseType: data['exerciseType'] as String? ?? '',
      completed: data['completed'] as int? ?? 0,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}  $h:$m';
  }

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class BreathingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  Future<void> saveSession({
    required String exerciseType,
    required int completed,
    required int durationSeconds,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in.');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('breathing_sessions')
        .add({
          'exerciseType': exerciseType,
          'completed': completed,
          'durationSeconds': durationSeconds,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<List<BreathingSession>> getHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in.');

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('breathing_sessions')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

    return snapshot.docs
        .map((doc) => BreathingSession._fromMap(doc.data()))
        .toList();
  }
}
