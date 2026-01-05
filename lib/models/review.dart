import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int rating;
  final String? review;

  Review({
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    required this.userId,
    required this.userName,
    required this.rating,
    this.userPhoto,
    this.review,
  });

  Map<String, dynamic> toMapForCreate() {
    return {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'posterPath': posterPath,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'movieTitle': movieTitle,
      'posterPath': posterPath,
      'userName': userName, 
      'rating': rating,
      'review': review,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
