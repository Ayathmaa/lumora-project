import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves a CBT journal entry for the currently signed-in user.
  ///
  /// Returns the auto-assigned journal number (1-based count).
  Future<int> saveCbtEntry({
    required Map<int, String> answers, // key = question number (1–8)
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
      'postAnxietyLevel': postAnxietyLevel,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Store each answer as Q1, Q2 … Q8
    for (final entry in answers.entries) {
      data['Q${entry.key}'] = entry.value;
    }

    await collectionRef.add(data);

    return journalNumber;
  }
}
