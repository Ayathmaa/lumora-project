import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// A fully-parsed ERP session record, free of Firestore types.
class ErpSession {
  final String date;
  final bool complete;
  final int durationMins;
  final int preAnxiety;
  final int postAnxiety;
  final String? difficulty;
  final List<String> triggerTypes;
  final String? reflection;

  const ErpSession({
    required this.date,
    required this.complete,
    required this.durationMins,
    required this.preAnxiety,
    required this.postAnxiety,
    required this.difficulty,
    required this.triggerTypes,
    required this.reflection,
  });

  factory ErpSession._fromMap(Map<String, dynamic> data) {
    final ts = data['timestamp'] as Timestamp?;
    return ErpSession(
      date: ts != null ? _formatDate(ts.toDate()) : '—',
      complete: (data['session_complete'] as int? ?? 0) == 1,
      durationMins: data['duration_mins'] as int? ?? 0,
      preAnxiety: data['pre_anxiety'] as int? ?? 0,
      postAnxiety: data['post_anxiety'] as int? ?? 0,
      difficulty: data['difficulty'] as String?,
      triggerTypes:
          (data['trigger_types'] as List?)?.cast<String>() ?? const [],
      reflection: data['reflection'] as String?,
    );
  }

  static String _formatDate(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }
}

class ErpTimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _sessionsCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('erp_sessions');
  }

  /// Saves an ERP session for the currently signed-in user.
  Future<void> saveSession({
    required bool sessionCompleted,
    required int durationMins,
    required int preAnxiety,
    required int postAnxiety,
    required String? difficulty,
    required List<String> triggerTypes,
    String? reflection,
  }) async {
    final collection = _sessionsCollection;
    if (collection == null) throw Exception('User not signed in.');

    final data = <String, dynamic>{
      'session_complete': sessionCompleted ? 1 : 0,
      'duration_mins': durationMins,
      'pre_anxiety': preAnxiety,
      'post_anxiety': postAnxiety,
      'difficulty': difficulty,
      'trigger_types': triggerTypes,
      'timestamp': FieldValue.serverTimestamp(),
      'clientCreatedAt': DateTime.now().toIso8601String(),
      'dateKey': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    if (reflection != null && reflection.isNotEmpty) {
      data['reflection'] = reflection;
    }

    await collection.add(data);
  }

  /// Returns a live stream of parsed ERP sessions ordered by most recent first.
  Stream<List<ErpSession>>? getSessionHistory() {
    return _sessionsCollection
        ?.orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ErpSession._fromMap(doc.data()))
                  .toList(),
        );
  }
}
