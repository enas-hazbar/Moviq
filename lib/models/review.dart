class Review {
  final String userId;
  final String userName;
  final int rating;
  final String review;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.review,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'createdAt': DateTime.now(),
    };
  }
}
