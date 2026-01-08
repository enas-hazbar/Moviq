import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PresenceService with WidgetsBindingObserver {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
  bucket: 'gs://moviq-1cbf7.firebasestorage.app',
);


  void start() {
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool online) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
