import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/tmdb_config.dart';
import '../screen/movie_details_page.dart';

class RecentlyViewedList extends StatelessWidget {
  const RecentlyViewedList({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recently_viewed')
        .orderBy('viewedAt', descending: true)
        .limit(8)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 92);
        }
        if (snapshot.hasError) {
          return const Text(
            'Unable to load recently viewed.',
            style: TextStyle(color: Colors.white70),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No recently viewed movies yet.',
            style: TextStyle(color: Colors.white70),
          );
        }

        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final int movieId = (data['movieId'] as num?)?.toInt() ?? 0;
              final String posterPath = (data['posterPath'] as String?) ?? '';
              final posterUrl = posterPath.isEmpty
                  ? null
                  : '${TmdbConfig.imageBaseUrl}$posterPath';

              return GestureDetector(
                onTap: movieId == 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailsPage(movieId: movieId),
                          ),
                        );
                      },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: posterUrl == null
                      ? Container(
                          width: 64,
                          height: 92,
                          color: Colors.white12,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.movie_outlined,
                            color: Colors.white38,
                            size: 22,
                          ),
                        )
                      : Image.network(
                          posterUrl,
                          width: 64,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 92,
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: Colors.white38,
                              size: 22,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
