import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _statsRef(int movieId) {
    return _db.collection('movies').doc(movieId.toString()).collection('meta').doc('stats');
  }

  DocumentReference<Map<String, dynamic>> _reviewRef(int movieId, String userId) {
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

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserReview(int movieId, String userId) {
    return _reviewRef(movieId, userId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserReview(int movieId, String userId) {
    return _reviewRef(movieId, userId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamStats(int movieId) {
    return _statsRef(movieId).snapshots();
  }

  /// Create or update the user's review (1 per user per movie).
  /// Also keeps aggregate stats: sumRatings + ratingCount.
  Future<void> upsertReview(int movieId, Review review) async {
    final reviewRef = _reviewRef(movieId, review.userId);
    final statsRef = _statsRef(movieId);

    await _db.runTransaction((tx) async {
      final existingSnap = await tx.get(reviewRef);

      if (!existingSnap.exists) {
        // Create new review
        tx.set(reviewRef, review.toMapForCreate());

        // stats: +rating, +1 count
        tx.set(statsRef, {
          'sumRatings': FieldValue.increment(review.rating),
          'ratingCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else {
        final data = existingSnap.data();
        final oldRating = (data?['rating'] as num?)?.toInt() ?? 0;

        // Update review
        tx.set(reviewRef, review.toMapForUpdate(), SetOptions(merge: true));

        // stats: +(new-old)
        tx.set(statsRef, {
          'sumRatings': FieldValue.increment(review.rating - oldRating),
        }, SetOptions(merge: true));
      }
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

      tx.set(statsRef, {
        'sumRatings': FieldValue.increment(-rating),
        'ratingCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    });
  }
}
