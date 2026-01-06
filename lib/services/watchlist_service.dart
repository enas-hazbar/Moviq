import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class WatchlistService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  Future<void> addToWatchlist(Map<String, dynamic> movie) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .doc(movie['id'].toString())
        .set({
      ...movie,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsWatched(Map<String, dynamic> movie) async {
    final ref = _db.collection('users').doc(uid);

    await ref.collection('watched').doc(movie['id'].toString()).set({
      ...movie,
      'watchedAt': FieldValue.serverTimestamp(),
    });

    await ref.collection('watchlist').doc(movie['id'].toString()).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchlistStream() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchedStream() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('watched')
        .orderBy('watchedAt', descending: true)
        .snapshots();
  }
}
