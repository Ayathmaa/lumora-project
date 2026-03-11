import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitFreedomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _habitCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('habit_trackers');
  }

  bool get isSignedIn => _auth.currentUser != null;

  /// Loads all habit trackers for the current user, ordered by creation date.
  /// Each map includes an `'id'` key with the document ID.
  Future<List<Map<String, dynamic>>> loadHabits() async {
    final collection = _habitCollection;
    if (collection == null) throw Exception('User not signed in.');
    final snapshot = await collection.orderBy('createdAt').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Creates a new habit tracker document.
  /// Returns the document ID used.
  Future<String> createHabit({
    required String docId,
    required String name,
    required String normalizedName,
  }) async {
    final collection = _habitCollection;
    if (collection == null) throw Exception('User not signed in.');

    await collection.doc(docId).set({
      'name': name,
      'normalizedName': normalizedName,
      'markedDates': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docId;
  }

  /// Marks a date as habit-free by appending it to the habit's markedDates.
  Future<void> markFreeDay({
    required String habitId,
    required String dateKey,
  }) async {
    final collection = _habitCollection;
    if (collection == null) throw Exception('User not signed in.');

    await collection.doc(habitId).update({
      'markedDates': FieldValue.arrayUnion([dateKey]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
