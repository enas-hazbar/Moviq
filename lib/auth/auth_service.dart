import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel _userFromFirebase(User user, {String? provider}) {
    return UserModel(
      uid: user.uid,
      email: user.email!,
      provider: provider ?? 'email',
    );
  }

Future<void> _ensureUserDoc(User user, {String? provider}) async {
  final db = _firestore;

  final email = user.email ?? '';
  final rawUsername =
      (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (email.isNotEmpty && email.contains('@') ? email.split('@').first : 'user');

  final username = rawUsername.toLowerCase();

  final userRef = db.collection('users').doc(user.uid);
  final usernameRef = db.collection('usernames').doc(username);

  await db.runTransaction((tx) async {
    final userSnap = await tx.get(userRef);

    // Create user doc if missing
    if (!userSnap.exists) {
      tx.set(userRef, {
        'uid': user.uid,
        'email': email,
        'provider': provider ?? 'unknown',
        'username': username,
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Ensure username index exists (only if not owned by someone else)
    final unameSnap = await tx.get(usernameRef);
    if (unameSnap.exists && unameSnap.data()?['uid'] != user.uid) {
      // Someone else owns that username (rare with displayName/email fallback)
      // You can choose to append uid suffix here if you want.
      throw Exception('USERNAME_TAKEN');
    }

    if (!unameSnap.exists) {
      tx.set(usernameRef, {'uid': user.uid});
    }
  });
}

Future<UserModel?> signUpWithEmail({
  required String email,
  required String password,
  String? username,
}) async {
  final cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final user = cred.user!;
  final db = _firestore;

  final normalizedUsername = username != null && username.trim().isNotEmpty
      ? username.trim().toLowerCase()
      : email.split('@').first.toLowerCase();

  final userRef = db.collection('users').doc(user.uid);
  final usernameRef = db.collection('usernames').doc(normalizedUsername);

  await db.runTransaction((tx) async {
    final usernameSnap = await tx.get(usernameRef);

    if (usernameSnap.exists) {
      throw Exception('USERNAME_TAKEN');
    }

    tx.set(userRef, {
      'uid': user.uid,
      'email': email,
      'provider': 'email',
      'username': normalizedUsername,
      'photoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    tx.set(usernameRef, {
      'uid': user.uid,
    });
  });

  return _userFromFirebase(user, provider: 'email');
}

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDoc(cred.user!, provider: 'email');

      return _userFromFirebase(cred.user!, provider: 'email');
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      await _ensureUserDoc(userCredential.user!, provider: 'google');

      return _userFromFirebase(userCredential.user!, provider: 'google');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );

      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken);

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      await _ensureUserDoc(userCredential.user!, provider: 'apple');

      return _userFromFirebase(userCredential.user!, provider: 'apple');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
