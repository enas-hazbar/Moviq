import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'tmdb_service.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TmdbService _tmdb = TmdbService();

  DocumentReference<Map<String, dynamic>> _statsRef(int movieId) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('meta')
        .doc('stats');
  }

  DocumentReference<Map<String, dynamic>> _reviewRef(
    int movieId,
    String userId,
  ) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(userId);
  }

  Query<Map<String, dynamic>> reviewsQuery(int movieId) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .orderBy('updatedAt', descending: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReviews(int movieId) {
    return reviewsQuery(movieId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserReview(
    int movieId,
    String userId,
  ) {
    return _reviewRef(movieId, userId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserReview(
    int movieId,
    String userId,
  ) {
    return _reviewRef(movieId, userId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamStats(int movieId) {
    return _statsRef(movieId).snapshots();
  }

  Future<void> upsertReview(int movieId, Review review) async {
    final reviewRef = _reviewRef(movieId, review.userId);
    final statsRef = _statsRef(movieId);

    await _db.runTransaction((tx) async {
      final existingSnap = await tx.get(reviewRef);

      if (!existingSnap.exists) {
        tx.set(reviewRef, review.toMapForCreate());

        tx.set(
          statsRef,
          {
            'sumRatings': FieldValue.increment(review.rating),
            'ratingCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      } else {
        final data = existingSnap.data();
        final oldRating = (data?['rating'] as num?)?.toInt() ?? 0;

        tx.set(
          reviewRef,
          review.toMapForUpdate(),
          SetOptions(merge: true),
        );

        tx.set(
          statsRef,
          {
            'sumRatings': FieldValue.increment(review.rating - oldRating),
          },
          SetOptions(merge: true),
        );
      }
    });

    final genreIds = await _fetchGenreIds(movieId);

    await _db
        .collection('users')
        .doc(review.userId)
        .collection('interactions')
        .add({
      'movieId': movieId,
      'genreIds': genreIds,
      'weight': 4,
      'source': 'review',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(int movieId, String userId) async {
    final reviewRef = _reviewRef(movieId, userId);
    final statsRef = _statsRef(movieId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(reviewRef);
      if (!snap.exists) return;

      final data = snap.data();
      final rating = (data?['rating'] as num?)?.toInt() ?? 0;

      tx.delete(reviewRef);

      tx.set(
        statsRef,
        {
          'sumRatings': FieldValue.increment(-rating),
          'ratingCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );
    });
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
