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

  static String? extractYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    final host = uri.host.toLowerCase();

    if (host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }

    if (host.contains('youtube.com')) {
      if (uri.queryParameters['v'] case final String value
          when value.trim().isNotEmpty) {
        return value.trim();
      }

      if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments.first == 'embed' ||
              uri.pathSegments.first == 'shorts')) {
        return uri.pathSegments[1];
      }
    }

    return null;
  }

  static String thumbnailUrlForVideoId(String videoId) {
    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }
}
