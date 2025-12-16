import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert Firebase User to UserModel
  UserModel _userFromFirebase(User user, {String? provider}) {
    return UserModel(
      uid: user.uid,
      email: user.email!,
      provider: provider ?? 'email',
    );
  }

  // Email & Password Sign Up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final userModel = _userFromFirebase(cred.user!, provider: 'email');

      // Optionally add username in Firestore
      if (username != null && username.isNotEmpty) {
        await _firestore.collection('users').doc(userModel.uid).set({
          'uid': userModel.uid,
          'email': userModel.email,
          'provider': userModel.provider,
          'username': username,
        });
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      print("Email Sign Up failed: $e");
      rethrow;
    } catch (e) {
      print("Email Sign Up failed: $e");
      return null;
    }
  }

  // Email & Password Sign In (no Firestore access)
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Return a UserModel directly; no Firestore read
      return _userFromFirebase(cred.user!, provider: 'email');
    } on FirebaseAuthException catch (e) {
      print("Email Sign In failed: $e");
      rethrow;
    } catch (e) {
      print("Email Sign In failed: $e");
      return null;
    }
  }

  // Google Sign-In
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
      final user = _userFromFirebase(userCredential.user!, provider: 'google');

      // Optionally create Firestore doc
      final doc = _firestore.collection('users').doc(user.uid);
      try {
        if (!(await doc.get()).exists) {
          await doc.set(user.toMap());
        }
      } catch (e) {
        print("Firestore access failed for Google sign-in: $e");
      }

      return user;
    } catch (e) {
      print("Google Sign-In failed: $e");
      rethrow;
    }
  }

  // Apple Sign-In
  Future<UserModel?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = _userFromFirebase(userCredential.user!, provider: 'apple');

      // Optionally create Firestore doc
      final doc = _firestore.collection('users').doc(user.uid);
      try {
        if (!(await doc.get()).exists) {
          await doc.set(user.toMap());
        }
      } catch (e) {
        print("Firestore access failed for Apple sign-in: $e");
      }

      return user;
    } catch (e) {
      print("Apple Sign-In failed: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Sign Out failed: $e");
    }
  }
}
