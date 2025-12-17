import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final int rating; // 1..10
  final String? review;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    this.review,
  });

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
