import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/moviq_scaffold.dart';
import '../config/tmdb_config.dart';
import 'home_page.dart';
import 'movie_details_page.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.reviews,
      currentBottomTab: MoviqBottomTab.dashboard,
      showTopNav: true,
      onTopTabSelected: (tab) {
        if (tab == MoviqTopTab.films) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      },
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs;
          if (docs == null || docs.isEmpty) {
            return const Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final String userName = data['userName'] ?? 'Unknown';
              final String reviewText = data['review'] ?? '';
              final int rating10 = (data['rating'] ?? 0) as int;
              final int starRating = (rating10 / 2).round(); // ⭐ FIXED
              final String movieTitle =
                  data['movieTitle'] ?? 'Unknown movie';
              final int? movieId = data['movieId'];
              final String? posterPath = data['posterPath'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: InkWell(
                  onTap: movieId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailsPage(movieId: movieId),
                            ),
                          );
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 Username
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 🎬 Poster + Review
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🎞 Poster
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: posterPath == null || posterPath.isEmpty
                                ? _posterPlaceholder()
                                : Image.network(
                                    '${TmdbConfig.imageBaseUrl}$posterPath',
                                    width: 90,
                                    height: 135,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _posterPlaceholder(),
                                  ),
                          ),

                          const SizedBox(width: 16),

                          // ⭐ Rating + Review
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < starRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 18,
                                      color: const Color(0xFFB37C78),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reviewText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🎥 Movie title
                      Text(
                        movieTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🎞 Fallback poster
  static Widget _posterPlaceholder() {
    return Container(
      width: 90,
      height: 135,
      color: Colors.white12,
      child: const Icon(
        Icons.movie_outlined,
        color: Colors.white38,
        size: 32,
      ),
    );
  }
}
