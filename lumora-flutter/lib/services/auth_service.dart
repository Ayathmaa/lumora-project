import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _webClientId =
      '567558823095-7hjlpgiehbapf48egcevgidkdo5q69ri.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(serverClientId: _webClientId);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in was cancelled.';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // Check if a username is already taken
  Future<bool> isUsernameTaken(String username) async {
    final doc =
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .get();
    return doc.exists;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // Save user profile to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String username,
    String? ageGroup,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final usernameRef = _firestore
        .collection('usernames')
        .doc(username.toLowerCase());

    await _firestore.runTransaction((transaction) async {
      final usernameDoc = await transaction.get(usernameRef);
      if (usernameDoc.exists && usernameDoc.data()?['uid'] != uid) {
        throw Exception("Username is already taken.");
      }

      transaction.set(userRef, {
        'name': name,
        'email': email,
        'username': username.toLowerCase(),
        'ageGroup': ageGroup ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!usernameDoc.exists) {
        transaction.set(usernameRef, {'uid': uid});
      }
    });
  }

  // Upgrade anonymous account to email/password (links credential, keeps UID)
  Future<void> upgradeAnonymousAccount({
    required String uid,
    required String name,
    required String email,
    required String password,
    String? ageGroup,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      // Link the anonymous user to an email/password credential
      await _auth.currentUser!.linkWithCredential(credential);
      // Update display name
      await _auth.currentUser!.updateDisplayName(name.trim());
      // Update Firestore: fill in the real details, remove isAnonymous flag
      await _firestore.collection('users').doc(uid).update({
        'name': name.trim(),
        'email': email.trim(),
        'ageGroup': ageGroup ?? '',
        'isAnonymous': false,
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in anonymously (guest)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Save a minimal guest profile (username only)
  Future<void> saveGuestProfile({
    required String uid,
    required String username,
  }) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'name': 'Guest',
      'email': '',
      'username': username.toLowerCase(),
      'ageGroup': '',
      'isAnonymous': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final usernameRef = _firestore
        .collection('usernames')
        .doc(username.toLowerCase());
    batch.set(usernameRef, {'uid': uid});

    await batch.commit();
    // Store username in Firebase Auth displayName so home screen
    // doesn't need a Firestore read on every launch.
    await _auth.currentUser?.updateDisplayName(username.trim());
  }

  // Fetch username from Firestore for the given uid
  Future<String?> getUsername(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['username'] as String?;
  }

  // Google sign-in can succeed before the app profile document is created.
  Future<bool> needsProfileCompletion(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final username = doc.data()?['username'] as String?;
    return !doc.exists || username == null || username.trim().isEmpty;
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Update profile details
  Future<void> updateUserProfile({
    required String name,
    required String username,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user signed in");

    final lowerUsername = username.toLowerCase();
    final userRef = _firestore.collection('users').doc(user.uid);
    final newUsernameRef = _firestore
        .collection('usernames')
        .doc(lowerUsername);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final currentUsername =
          (userDoc.data()?['username'] as String?)?.toLowerCase();
      final usernameDoc = await transaction.get(newUsernameRef);

      if (currentUsername != lowerUsername) {
        if (usernameDoc.exists && usernameDoc.data()?['uid'] != user.uid) {
          throw Exception("Username is already taken.");
        }

        if (currentUsername != null && currentUsername.isNotEmpty) {
          transaction.delete(
            _firestore.collection('usernames').doc(currentUsername),
          );
        }
      }

      if (!usernameDoc.exists) {
        transaction.set(newUsernameRef, {'uid': user.uid});
      }

      final profileData = <String, dynamic>{
        'name': name,
        'email': user.email ?? '',
        'username': lowerUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!userDoc.exists) {
        profileData['ageGroup'] = '';
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }
      if (photoURL != null) {
        profileData['photoURL'] = photoURL;
      }

      transaction.set(userRef, profileData, SetOptions(merge: true));
    });

    // Update Firebase Auth profile
    await user.updateDisplayName(name);
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user signed in");
    if (user.email == null) throw Exception("User has no email");
    if (!hasPasswordProvider) {
      throw Exception(
        "This account uses Google Sign-In. Change your password in your Google Account settings.",
      );
    }

    try {
      // Re-authenticate before changing sensitive credentials.
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          throw Exception("Current password is incorrect.");
        case 'weak-password':
          throw Exception("New password should be at least 6 characters.");
        case 'requires-recent-login':
          throw Exception("Please log out, log in again, then retry.");
        default:
          throw Exception(_handleAuthException(e));
      }
    }
  }
}
