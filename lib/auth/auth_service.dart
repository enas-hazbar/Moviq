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
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      final email = user.email ?? '';

      await ref.set({
        'uid': user.uid,
        'email': email,
        'provider': provider ?? 'unknown',
        'username':
            (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : (email.isNotEmpty ? email.split('@').first : 'User'),
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDoc(cred.user!, provider: 'email');

      if (username != null && username.trim().isNotEmpty) {
        await _firestore.collection('users').doc(cred.user!.uid).update({
          'username': username.trim(),
        });
      }

      return _userFromFirebase(cred.user!, provider: 'email');
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
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
