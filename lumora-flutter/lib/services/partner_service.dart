import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerUser {
  final String uid;
  final String username;
  final String displayName;
  final String avatarUrl;

  PartnerUser({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  factory PartnerUser.fromMap(Map<String, dynamic> map) {
    return PartnerUser(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }
}

class PartnerInvite {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;

  // Optional field if we fetch sender details to display
  final PartnerUser? sender;

  PartnerInvite({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.createdAt,
    this.sender,
  });

  factory PartnerInvite.fromDoc(DocumentSnapshot doc, {PartnerUser? sender}) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerInvite(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sender: sender,
    );
  }
}

class PartnerPreferences {
  final bool shareAnxietyRemaining;
  final bool shareDailyMood;
  final bool shareJourneyCalendar;

  PartnerPreferences({
    this.shareAnxietyRemaining = false,
    this.shareDailyMood = false,
    this.shareJourneyCalendar = false,
  });

  factory PartnerPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PartnerPreferences();
    return PartnerPreferences(
      shareAnxietyRemaining: map['shareAnxietyRemaining'] == true,
      shareDailyMood: map['shareDailyMood'] == true,
      shareJourneyCalendar: map['shareJourneyCalendar'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shareAnxietyRemaining': shareAnxietyRemaining,
      'shareDailyMood': shareDailyMood,
      'shareJourneyCalendar': shareJourneyCalendar,
    };
  }
}

class PartnerService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not signed in.");
    return user.uid;
  }

  /// Search for users by username
  Future<List<PartnerUser>> searchUsers(String username) async {
    try {
      final result = await _functions.httpsCallable('searchUsers').call({
        'username': username,
      });
      final List data = result.data as List;
      return data
          .map((e) => PartnerUser.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception("Failed to search users: \$e");
    }
  }

  /// Stream pending invites received by the current user
  Stream<List<PartnerInvite>> streamPendingInvites() {
    return _db
        .collection('partner_invites')
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          List<PartnerInvite> invites = [];
          for (var doc in snapshot.docs) {
            // Fetch sender details
            final data = doc.data();
            final senderId = data['senderId'] as String?;
            PartnerUser? sender;
            if (senderId != null) {
              final senderDoc =
                  await _db.collection('users').doc(senderId).get();
              if (senderDoc.exists) {
                final stData = senderDoc.data()!;
                stData['uid'] = senderId;
                sender = PartnerUser.fromMap(stData);
              }
            }
            invites.add(PartnerInvite.fromDoc(doc, sender: sender));
          }
          return invites;
        });
  }

  /// Stream current user's partner preferences
  Stream<PartnerPreferences> streamMyPreferences() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      final data = doc.data();
      return PartnerPreferences.fromMap(data?['partnerPreferences']);
    });
  }

  /// Stream partner details if linked
  Stream<PartnerUser?> streamMyPartner() {
    return _db.collection('users').doc(_uid).snapshots().asyncMap((doc) async {
      final partnerId = doc.data()?['partnerId'] as String?;
      if (partnerId == null) return null;

      final partnerDoc = await _db.collection('users').doc(partnerId).get();
      if (!partnerDoc.exists) return null;

      final pData = partnerDoc.data()!;
      pData['uid'] = partnerId;
      return PartnerUser.fromMap(pData);
    });
  }

  /// Stream partner's preferences (what they share with me)
  Stream<PartnerPreferences> streamPartnerPreferences() {
    return _db.collection('users').doc(_uid).snapshots().asyncMap((doc) async {
      final partnerId = doc.data()?['partnerId'] as String?;
      if (partnerId == null) return PartnerPreferences();

      final partnerDoc = await _db.collection('users').doc(partnerId).get();
      return PartnerPreferences.fromMap(
        partnerDoc.data()?['partnerPreferences'],
      );
    });
  }

  /// Update current user's sharing preferences
  Future<void> updatePreferences(PartnerPreferences prefs) async {
    try {
      await _db.collection('users').doc(_uid).update({
        'partnerPreferences': prefs.toMap(),
      });
    } catch (e) {
      throw Exception("Failed to update preferences: \$e");
    }
  }

  /// Send an invite using Cloud Function
  Future<void> sendInvite(String receiverId) async {
    try {
      await _functions.httpsCallable('sendPartnerInvite').call({
        'receiverId': receiverId,
      });
    } catch (e) {
      throw Exception("Failed to send invite: \$e");
    }
  }

  /// Accept an invite via Cloud Function
  Future<void> acceptInvite(String inviteId) async {
    try {
      await _functions.httpsCallable('acceptPartnerInvite').call({
        'inviteId': inviteId,
      });
    } catch (e) {
      throw Exception("Failed to accept invite: \$e");
    }
  }

  /// Decline an invite (just delete the doc directly, simple enough)
  Future<void> declineInvite(String inviteId) async {
    try {
      final inviteDoc =
          await _db.collection('partner_invites').doc(inviteId).get();
      if (inviteDoc.exists && inviteDoc.data()?['receiverId'] == _uid) {
        await inviteDoc.reference.update({'status': 'declined'});
      }
    } catch (e) {
      throw Exception("Failed to decline invite: \$e");
    }
  }

  /// Remove current partner via Cloud Function
  Future<void> removePartner() async {
    try {
      await _functions.httpsCallable('removePartner').call();
    } catch (e) {
      throw Exception("Failed to remove partner: \$e");
    }
  }
}
