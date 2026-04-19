import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// A fully-parsed CBT journal entry, free of Firestore types.
class JournalEntry {
  final int journalNumber;
  final int preAnxietyLevel;
  final int postAnxietyLevel;
  final DateTime createdAt;
  final Map<int, String> answers; // Q1–Q8

  const JournalEntry({
    required this.journalNumber,
    required this.preAnxietyLevel,
    required this.postAnxietyLevel,
    required this.createdAt,
    required this.answers,
  });

  factory JournalEntry._fromMap(Map<String, dynamic> data) {
    final ts = data['createdAt'] as Timestamp?;
    final answers = <int, String>{};
    for (int i = 1; i <= 8; i++) {
      final val = data['Q$i'] as String?;
      if (val != null && val.isNotEmpty) answers[i] = val;
    }
    return JournalEntry(
      journalNumber: data['journalNumber'] as int? ?? 0,
      preAnxietyLevel: data['preAnxietyLevel'] as int? ?? 0,
      postAnxietyLevel: data['postAnxietyLevel'] as int? ?? 0,
      createdAt: ts?.toDate() ?? DateTime.now(),
      answers: answers,
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
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}  $h:$m';
  }
}

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves a CBT journal entry for the currently signed-in user.
  ///
  /// Returns the auto-assigned journal number (1-based count).
  Future<int> saveCbtEntry({
    required Map<int, String> answers, // key = question number (1–8)
    required int preAnxietyLevel,
    required int postAnxietyLevel,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in.');

    final collectionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('cbt_journal');

    // Determine the next journal number by counting existing documents.
    final snapshot = await collectionRef.count().get();
    final journalNumber = (snapshot.count ?? 0) + 1;

    final data = <String, dynamic>{
      'journalNumber': journalNumber,
      'preAnxietyLevel': preAnxietyLevel,
      'postAnxietyLevel': postAnxietyLevel,
      'createdAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': DateTime.now().toIso8601String(),
      'dateKey': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    // Store each answer as Q1, Q2 … Q8
    for (final entry in answers.entries) {
      data['Q${entry.key}'] = entry.value;
    }

    await collectionRef.add(data);

    return journalNumber;
  }

  /// Returns all past journal entries for the current user, most recent first.
  /// Returns null if the user is not signed in.
  Stream<List<JournalEntry>>? getHistory() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cbt_journal')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => JournalEntry._fromMap(doc.data()))
                  .toList(),
        );
  }
}
