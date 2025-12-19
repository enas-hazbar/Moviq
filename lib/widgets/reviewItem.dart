import 'package:flutter/material.dart';
class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.username,
    required this.movieTitle,
    required this.posterUrl,
    required this.rating,
    required this.reviewText,
  });

  final String username;
  final String movieTitle;
  final String posterUrl;
  final int rating;
  final String reviewText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie poster
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      posterUrl,
                      width: 90,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movieTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Review + stars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stars
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFE5A3A3),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Review text
                    Text(
                      '"$reviewText"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
