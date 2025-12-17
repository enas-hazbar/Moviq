import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference reviewsRef(int movieId) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews');
  }

  Future<void> addReview(int movieId, Review review) {
    return reviewsRef(movieId).add(review.toMap());
  }

  Stream<QuerySnapshot> getReviews(int movieId) {
    return reviewsRef(movieId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
