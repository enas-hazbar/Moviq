import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/tmdb_config.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final reviewsStream = FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .handleError((_) {});

    final listsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot>(
      stream: reviewsStream,
      builder: (context, reviewsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: listsStream,
          builder: (context, listsSnap) {
            if (reviewsSnap.connectionState == ConnectionState.waiting ||
                listsSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 80);
            }
            if (reviewsSnap.hasError || listsSnap.hasError) {
              return const Text(
                'Unable to load recent activity.',
                style: TextStyle(color: Colors.white70),
              );
            }

            final items = <_ActivityItem>[];

            final reviewDocs = reviewsSnap.data?.docs ?? [];
            for (final doc in reviewDocs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add(
                _ActivityItem.review(
                  createdAt: data['createdAt'] as Timestamp?,
                  movieTitle: (data['movieTitle'] as String?) ?? 'Unknown movie',
                  posterPath: (data['posterPath'] as String?) ?? '',
                  rating10: (data['rating'] as num?)?.toInt() ?? 0,
                  reviewText: (data['review'] as String?) ?? '',
                ),
              );
            }

            final listDocs = listsSnap.data?.docs ?? [];
            for (final doc in listDocs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add(
                _ActivityItem.list(
                  createdAt: data['createdAt'] as Timestamp?,
                  listName: (data['name'] as String?) ?? 'List',
                  listId: doc.id,
                ),
              );
            }

            items.sort((a, b) => b.millis.compareTo(a.millis));
            final visible = items.take(3).toList();

            if (visible.isEmpty) {
              return const Text(
                'No recent activity yet.',
                style: TextStyle(color: Colors.white70),
              );
            }

            return Column(
              children: [
                for (final item in visible)
                  _RecentActivityRow(item: item, userId: userId!),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActivityItem {
  _ActivityItem({
    required this.type,
    required this.createdAt,
    this.movieTitle,
    this.posterPath,
    this.rating10,
    this.reviewText,
    this.listName,
    this.listId,
  });

  factory _ActivityItem.review({
    required Timestamp? createdAt,
    required String movieTitle,
    required String posterPath,
    required int rating10,
    required String reviewText,
  }) {
    return _ActivityItem(
      type: _ActivityType.review,
      createdAt: createdAt,
      movieTitle: movieTitle,
      posterPath: posterPath,
      rating10: rating10,
      reviewText: reviewText,
    );
  }

  factory _ActivityItem.list({
    required Timestamp? createdAt,
    required String listName,
    required String listId,
  }) {
    return _ActivityItem(
      type: _ActivityType.list,
      createdAt: createdAt,
      listName: listName,
      listId: listId,
    );
  }

  final _ActivityType type;
  final Timestamp? createdAt;
  final String? movieTitle;
  final String? posterPath;
  final int? rating10;
  final String? reviewText;
  final String? listName;
  final String? listId;

  int get millis => createdAt?.millisecondsSinceEpoch ?? 0;
}

enum _ActivityType { review, list }

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.item, required this.userId});

  final _ActivityItem item;
  final String userId;

  @override
  Widget build(BuildContext context) {
    if (item.type == _ActivityType.list) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListPosterCollage(
              userId: userId,
              listId: item.listId,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Created list',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.listName ?? 'List',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final posterPath = item.posterPath ?? '';
    final posterUrl =
        posterPath.isEmpty ? null : '${TmdbConfig.imageBaseUrl}$posterPath';
    final rating10 = item.rating10 ?? 0;
    final starRating = ((rating10 / 2).ceil()).clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: posterUrl == null
                ? Container(
                    width: 60,
                    height: 84,
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
                    width: 60,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 84,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < starRating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFB37C78),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$rating10/10',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (item.reviewText ?? '').trim().isEmpty ? 'Rating only' : item.reviewText!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  item.movieTitle ?? 'Unknown movie',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPosterCollage extends StatelessWidget {
  const _ListPosterCollage({
    required this.userId,
    required this.listId,
  });

  final String userId;
  final String? listId;

  @override
  Widget build(BuildContext context) {
    if (listId == null || listId!.isEmpty) {
      return _posterPlaceholder();
    }
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .limit(4)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final posters = docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['posterPath'] as String?)
            .where((path) => path != null && path!.isNotEmpty)
            .cast<String>()
            .toList();

        if (posters.isEmpty) {
          return _posterPlaceholder();
        }

        if (posters.length == 1) {
          return _posterImage(posters.first);
        }

        if (posters.length == 2) {
          return _posterSplitTwo(posters);
        }

        return _posterSplitGrid(posters.take(4).toList());
      },
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 60,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.list_alt,
        color: Colors.white54,
        size: 26,
      ),
    );
  }

  Widget _posterImage(String posterPath) {
    final url = '${TmdbConfig.imageBaseUrl}$posterPath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 60,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _posterPlaceholder(),
      ),
    );
  }

  Widget _posterSplitTwo(List<String> posters) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 60,
        height: 84,
        child: Row(
          children: [
            _posterTile(posters[0], 30, 84),
            _posterTile(posters[1], 30, 84),
          ],
        ),
      ),
    );
  }

  Widget _posterSplitGrid(List<String> posters) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 60,
        height: 84,
        child: Column(
          children: [
            Row(
              children: [
                _posterTile(posters[0], 30, 42),
                _posterTile(posters.length > 1 ? posters[1] : '', 30, 42),
              ],
            ),
            Row(
              children: [
                _posterTile(posters.length > 2 ? posters[2] : '', 30, 42),
                _posterTile(posters.length > 3 ? posters[3] : '', 30, 42),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterTile(String posterPath, double width, double height) {
    if (posterPath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.white12,
        alignment: Alignment.center,
        child: const Icon(
          Icons.movie_outlined,
          color: Colors.white38,
          size: 16,
        ),
      );
    }
    final url = '${TmdbConfig.imageBaseUrl}$posterPath';
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.white12,
        alignment: Alignment.center,
        child: const Icon(
          Icons.movie_outlined,
          color: Colors.white38,
          size: 16,
        ),
      ),
    );
  }
}
