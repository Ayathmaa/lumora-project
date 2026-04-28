import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/meditation.dart';

class MeditationCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  Stream<List<Meditation>> streamMeditations() {
    if (!isSignedIn) {
      return Stream.value(const <Meditation>[]);
    }

    return _firestore
        .collection('meditations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final meditations = <Meditation>[];
          for (final doc in snapshot.docs) {
            try {
              meditations.add(Meditation.fromDoc(doc));
            } catch (error, stackTrace) {
              debugPrint('Skipping malformed meditation ${doc.id}: $error');
              debugPrintStack(stackTrace: stackTrace);
            }
          }

          meditations.sort((a, b) {
            final categoryCompare = MeditationCategory.values
                .indexOf(a.category)
                .compareTo(MeditationCategory.values.indexOf(b.category));
            if (categoryCompare != 0) return categoryCompare;
            return a.sortOrder.compareTo(b.sortOrder);
          });

          return meditations;
        });
  }
}
