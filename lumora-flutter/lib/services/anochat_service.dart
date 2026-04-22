import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'gamification_utils.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class AnoPost {
  final String id;
  final String uid;
  final String authorName;
  final String authorLevelTitle;
  final int authorLevelNumber;
  final String content;
  final String category;
  final DateTime createdAt;
  final int supportCount;
  final int relateCount;
  final int encouragementCount;
  final bool requiresReview;
  final bool isHidden;

  const AnoPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.authorLevelTitle,
    required this.authorLevelNumber,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.supportCount,
    required this.relateCount,
    required this.encouragementCount,
    required this.requiresReview,
    this.isHidden = false,
  });

  int get totalReactions => supportCount + relateCount + encouragementCount;
}

// ── Service ────────────────────────────────────────────────────────────────

class AnoChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();

  static const int postMaxLength = 400;

  static const List<String> categories = [
    'Struggling Today',
    'Small Win',
    'ERP Progress',
    'Seeking Advice',
    'Motivation',
  ];

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('anoPosts');

  AnoPost _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String? resolvedAuthorName,
  }) {
    final d = doc.data();
    final counts = (d['reactionCounts'] as Map<String, dynamic>?) ?? {};
    return AnoPost(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      authorName:
          resolvedAuthorName?.trim().isNotEmpty == true
              ? resolvedAuthorName!.trim()
              : (d['authorName'] as String? ?? 'Anonymous'),
      authorLevelTitle: d['authorLevelTitle'] as String? ?? 'Novice',
      authorLevelNumber: (d['authorLevelNumber'] as num?)?.toInt() ?? 1,
      content: d['content'] as String? ?? '',
      category: d['category'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      supportCount: (counts['support'] as num?)?.toInt() ?? 0,
      relateCount: (counts['relate'] as num?)?.toInt() ?? 0,
      encouragementCount: (counts['encouragement'] as num?)?.toInt() ?? 0,
      requiresReview: d['requiresReview'] as bool? ?? false,
      isHidden: d['isHidden'] as bool? ?? false,
    );
  }

  /// Streams the latest 50 posts. Uses server-side composite indexes for performance.
  Stream<List<AnoPost>> postsStream({String? category}) {
    Query<Map<String, dynamic>> query = _posts;

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs.map(_fromDoc).where((p) => !p.isHidden).toList();
        });
  }

  Future<void> createPost({
    required String content,
    required String category,
    required String authorName,
  }) async {
    final uid = _uid;
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('Post cannot be empty.');
    if (trimmed.length > postMaxLength) {
      throw Exception('Post exceeds $postMaxLength characters.');
    }
    if (!categories.contains(category)) throw Exception('Invalid category.');

    final username = await _auth.getUsername(uid);
    final safeAuthorName =
        username?.trim().isNotEmpty == true ? username!.trim() : authorName;

    // Fetch user XP to figure out level
    int userXp = 0;
    try {
      final doc = await _db.collection('users').doc(uid).collection('user_stats').doc('gamification').get();
      if (doc.exists) {
        userXp = doc.data()?['xp'] as int? ?? 0;
      }
    } catch (_) {}

    final levelTitle = GamificationUtils.getLevelTitle(userXp);
    final levelNumber = GamificationUtils.getLevelNumber(userXp);

    await _posts.add({
      'uid': uid,
      'authorName': safeAuthorName,
      'authorLevelTitle': levelTitle,
      'authorLevelNumber': levelNumber,
      'content': trimmed,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'reactionCounts': {'support': 0, 'relate': 0, 'encouragement': 0},
      'requiresReview': false, // Let Cloud Function update this
      'isHidden': false, // Let Cloud Function update this
    });
  }

  Future<void> deletePost(String postId) async {
    final uid = _uid;
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return;
    if ((doc.data()!['uid'] as String?) != uid) {
      throw Exception('Cannot delete another user\'s post.');
    }
    await _posts.doc(postId).delete();
  }

  /// Toggles a reaction. Calling with the same type the user already selected
  /// removes it (un-react). Calling with a different type swaps it.
  Future<void> toggleReaction(String postId, String reactionType) async {
    final uid = _uid;
    final reactionRef = _db
        .collection('users')
        .doc(uid)
        .collection('anoReactions')
        .doc(postId);

    final snap = await reactionRef.get();
    if (snap.exists) {
      final current = snap.data()!['type'] as String;
      if (current == reactionType) {
        // Same type — remove reaction.
        await reactionRef.delete();
      } else {
        // Different type — swap reaction.
        await reactionRef.set({'type': reactionType});
      }
    } else {
      // First reaction.
      await reactionRef.set({'type': reactionType});
    }
  }

  /// Streams all of the current user's reactions as `Map<postId, reactionType>`.
  Stream<Map<String, String>> myReactionsStream() {
    try {
      final uid = _uid;
      return _db
          .collection('users')
          .doc(uid)
          .collection('anoReactions')
          .snapshots()
          .map(
            (snap) => {
              for (final doc in snap.docs)
                if (doc.data()['type'] is String)
                  doc.id: doc.data()['type'] as String,
            },
          );
    } catch (_) {
      return Stream.value({});
    }
  }
}
