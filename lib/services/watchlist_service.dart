import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tmdb_service.dart';

class WatchlistService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _tmdb = TmdbService();

  String get uid => _auth.currentUser!.uid;

  Future<void> addToWatchlist(Map<String, dynamic> movie) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .doc(movie['id'].toString())
        .set({
      ...movie,
      'addedAt': FieldValue.serverTimestamp(),
    });

    final movieId = movie['id'];
    if (movieId is int) {
      final genreIds = await _fetchGenreIds(movieId);

      await _db.collection('users').doc(uid).collection('interactions').add({
        'movieId': movieId,
        'genreIds': genreIds,
        'weight': 2,
        'source': 'watchlist',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
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

  Future<List<int>> _fetchGenreIds(int movieId) async {
    try {
      final details = await _tmdb.getMovieDetails(movieId);
      final genres = details['genres'];

      if (genres is List) {
        return genres
            .map((g) => g['id'])
            .whereType<int>()
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }
}
