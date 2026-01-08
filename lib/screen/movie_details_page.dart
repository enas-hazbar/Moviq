import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tmdb_service.dart';
import '../services/review_service.dart';
import '../config/tmdb_config.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../widgets/trailer_player.dart';
import 'actor_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final TmdbService _tmdbService = TmdbService();
  final ReviewService _reviewService = ReviewService();
  String? _username;
  late Future<Map<String, dynamic>> _movie;
  late Future<List<dynamic>> _videos;
  late Future<Map<String, dynamic>> _credits;
  late Future<Map<String, dynamic>> _providers;
  late Future<List<Movie>> _similar;
  Stream<bool> _isInWatchlist(int movieId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchlist')
      .doc(movieId.toString())
      .snapshots()
      .map((doc) => doc.exists);
}
Stream<bool> _isWatched(int movieId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watched')
      .doc(movieId.toString())
      .snapshots()
      .map((doc) => doc.exists);
}

Future<void> _loadUsername() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!mounted) return;

  setState(() {
    _username = doc.data()?['username'] as String?;
  });
}
  @override
  void initState() {
    super.initState();
      _loadUsername(); 
    _movie = _tmdbService.getMovieDetails(widget.movieId);
    _movie.then((data) {
      _logRecentlyViewed(
        movieId: widget.movieId,
        title: (data['title'] ?? '').toString(),
        posterPath: (data['poster_path'] ?? '').toString(),
      );
    });
    _videos = _tmdbService.getMovieVideos(widget.movieId);
    _credits = _tmdbService.getCredits(widget.movieId);
    _providers = _tmdbService.getWatchProviders(widget.movieId);
    _similar = _tmdbService.getSimilarMovies(widget.movieId);
  }

  Future<void> _logRecentlyViewed({
    required int movieId,
    required String title,
    required String posterPath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (title.isEmpty && posterPath.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recently_viewed')
          .doc(movieId.toString())
          .set({
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'viewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignore permission errors.
    }
  }
  Widget _watchlistButton({
  required int movieId,
  required String title,
  required String posterPath,
}) {
  return StreamBuilder<bool>(
    stream: _isInWatchlist(movieId),
    builder: (context, snapshot) {
      final inWatchlist = snapshot.data ?? false;

     return ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor:
        inWatchlist ? Colors.white12 : const Color(0xFFE5A3A3),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  icon: Icon(
    inWatchlist ? Icons.check : Icons.add,
    color: Colors.white,
  ),
  label: Text(
    inWatchlist ? 'In Watchlist' : 'Add to Watchlist',
  ),
  onPressed: () async {
    if (inWatchlist) {
      await _removeFromWatchlist(movieId);
    } else {
      await _addToWatchlist(
        movieId: movieId,
        title: title,
        posterPath: posterPath,
      );
    }
  },
);
    },
  );
}
Widget _watchedButton({
  required int movieId,
  required String title,
  required String posterPath,
}) {
  return StreamBuilder<bool>(
    stream: _isWatched(movieId),
    builder: (context, snapshot) {
      final isWatched = snapshot.data ?? false;

      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isWatched ? Colors.greenAccent.withOpacity(0.9) : Colors.white12,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          isWatched ? Icons.check_circle : Icons.visibility,
          color: isWatched ? Colors.black : Colors.white,
        ),
        label: Text(
          isWatched ? 'Watched' : 'Mark Watched',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isWatched ? Colors.black : Colors.white,
          ),
        ),
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          if (isWatched) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('watched')
                .doc(movieId.toString())
                .delete();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed from watched')),
            );
          } else {
            await _markAsWatched(
              movieId: movieId,
              title: title,
              posterPath: posterPath,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Marked as watched')),
            );
          }
        },
      );
    },
  );
}


Future<void> _addToWatchlist({
  required int movieId,
  required String title,
  required String posterPath,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchlist')
      .doc(movieId.toString())
      .set({
    'movieId': movieId,
    'title': title,
    'posterPath': posterPath,
    'addedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> _removeFromWatchlist(int movieId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchlist')
      .doc(movieId.toString())
      .delete();
}
Future<void> _markAsWatched({
  required int movieId,
  required String title,
  required String posterPath,
}) 
async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

  // 1️⃣ Add to watched
  await userRef.collection('watched').doc(movieId.toString()).set({
    'movieId': movieId,
    'title': title,
    'posterPath': posterPath,
    'watchedAt': FieldValue.serverTimestamp(),
  });

  // 2️⃣ Remove from watchlist (if exists)
  await userRef.collection('watchlist').doc(movieId.toString()).delete();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Movie Details'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _movie,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movie = snapshot.data!;
          final tmdbRating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0;
          final String posterPath = movie['poster_path'] ?? '';
          final String movieTitle = movie['title'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  TmdbConfig.imageBaseUrl + posterPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 350,
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.movie_outlined, color: Colors.white38, size: 50),
                  ),
                ),
              ),
                const SizedBox(height: 16),

                Text(
                  movie['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
const SizedBox(height: 12),
if (FirebaseAuth.instance.currentUser != null)
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.04),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Row(
    children: [
      Expanded(
        child: _watchlistButton(
          movieId: widget.movieId,
          title: movieTitle,
          posterPath: posterPath,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _watchedButton(
          movieId: widget.movieId,
          title: movieTitle,
          posterPath: posterPath,
        ),
      ),
    ],
  ),
),

const SizedBox(height: 16),

            const SizedBox(height: 16),

            _buildRatingsRow(tmdbRating),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: ((movie['genres'] as List?) ?? [])
                      .map((g) => Chip(label: Text(g['name'] ?? '')))
                      .toList(),
                ),

                const SizedBox(height: 16),

                Text(
                  movie['overview'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 24),

                _buildTrailer(),
                const SizedBox(height: 24),

                _buildProviders(),
                const SizedBox(height: 24),

                _buildCast(),
                const SizedBox(height: 24),
                _buildReviewsHeader(
                  movieTitle: movieTitle,
                  posterPath: posterPath,
                ),
                const SizedBox(height: 12),

                _buildReviewsList(),
                const SizedBox(height: 24),

                _buildSimilarMovies(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingsRow(double tmdbRating) {
    return StreamBuilder(
      stream: _reviewService.streamStats(widget.movieId),
      builder: (context, snapshot) {
        double userAverage = 0.0;
        int ratingCount = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final sumRatings = (data['sumRatings'] as num?)?.toDouble() ?? 0.0;
          ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

          if (ratingCount > 0) {
            userAverage = sumRatings / ratingCount;
          }
        }

        return Row(
          children: [
            _ratingBox(
              title: 'TMDB rating',
              value: tmdbRating.toStringAsFixed(1),
              subtitle: 'Official',
              valueColor: Colors.white,
            ),
            const SizedBox(width: 12),
            _ratingBox(
              title: 'User rating',
              value: ratingCount == 0 ? '—' : userAverage.toStringAsFixed(1),
              subtitle: ratingCount == 0
                  ? 'No ratings'
                  : '$ratingCount ratings',
              valueColor: Colors.amber,
            ),
          ],
        );
      },
    );
  }

  Widget _ratingBox({
    required String title,
    required String value,
    String? subtitle,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              '⭐ $value',
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

 Widget _buildReviewsHeader({
  required String movieTitle,
  required String posterPath,
}) {
    final user = FirebaseAuth.instance.currentUser;

    return Row(
      children: [
        const Expanded(
          child: Text(
            'User reviews',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please log in to add a rating/review'),
                ),
              );
              return;
            }
_openReviewSheet(
  movieTitle: movieTitle,
  posterPath: posterPath,
);
          },
          child: const Text('+ Review'),
        ),
      ],
    );
  }

Future<void> _openReviewSheet({
  required String movieTitle,
  required String posterPath,
}) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
      return _ReviewSheet(
        movieId: widget.movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        userId: user.uid,
        userName: (_username != null && _username!.trim().isNotEmpty)
        ? _username!.trim()
        : (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'User'),
        reviewService: _reviewService,
      );

      },
    );

    if (mounted) setState(() {});
  }
  /// Trailer
  Widget _buildTrailer() {
    return FutureBuilder<List<dynamic>>(
      future: _videos,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final trailer = snapshot.data!.firstWhere(
          (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
          orElse: () => null,
        );

        if (trailer == null) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trailer',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TrailerPlayer(youtubeKey: trailer['key']),
          ],
        );
      },
    );
  }

  ///  Where to watch
  Widget _buildProviders() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _providers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final nl = snapshot.data!['NL'];
        if (nl == null || nl['flatrate'] == null) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where to watch',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (nl['flatrate'] as List)
                  .map((p) => Chip(label: Text(p['provider_name'] ?? '')))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  ///  Cast
  Widget _buildCast() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _credits,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final cast = (snapshot.data!['cast'] as List).take(10);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cast',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: cast.map<Widget>((actor) {
                  final profilePath = actor['profile_path'];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActorDetailsPage(personId: actor['id']),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profilePath != null
                                ? NetworkImage(
                                    TmdbConfig.imageBaseUrl + profilePath,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 90,
                            child: Text(
                              actor['name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Reviews list (user’s review first)
  Widget _buildReviewsList() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: _reviewService.getReviews(widget.movieId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text(
            'No reviews yet',
            style: TextStyle(color: Colors.white70),
          );
        }

        final List<Map<String, dynamic>> items = docs.map((d) {
          final data = d.data();
          data['_docId'] = d.id;
          return data;
        }).toList();

        if (user != null) {
          items.sort((a, b) {
            final aMine = a['_docId'] == user.uid;
            final bMine = b['_docId'] == user.uid;
            if (aMine && !bMine) return -1;
            if (!aMine && bMine) return 1;
            return 0;
          });
        }

        return Column(
          children: items.map((data) {
            final isMine = user != null && data['_docId'] == user.uid;

            return Card(
              color: Colors.grey.shade900,
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['userName'] ?? 'User',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (isMine)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () async {
                      await _openReviewSheet(
                        movieTitle: data['movieTitle'] ?? 'Unknown movie',
                        posterPath: data['posterPath'] ?? '',
                      );
                                              },
                      ),
                  ],
                ),
                subtitle: Text(
                  (data['review'] == null ||
                          (data['review'] as String).trim().isEmpty)
                      ? 'Rating only'
                      : data['review'],
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  '${data['rating'] ?? 0}/10',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  ///  Similar movies
  Widget _buildSimilarMovies() {
    return FutureBuilder<List<Movie>>(
      future: _similar,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final movies = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Similar Movies',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailsPage(movieId: movie.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          TmdbConfig.imageBaseUrl + movie.posterPath,
                          width: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final String userId;
  final String userName;
  final ReviewService reviewService;


  const _ReviewSheet({
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    required this.userId,
    required this.userName,
    required this.reviewService,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  int _rating = 0; // require rating 1..10
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: StreamBuilder(
        stream: widget.reviewService.streamUserReview(
          widget.movieId,
          widget.userId,
        ),
        builder: (context, snapshot) {
          final exists = snapshot.hasData && snapshot.data!.exists;

          if (exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final existingRating = (data['rating'] as num?)?.toInt() ?? 0;
            final existingReview = (data['review'] as String?) ?? '';

            if (_rating == 0) _rating = existingRating;
            if (_controller.text.isEmpty && existingReview.isNotEmpty) {
              _controller.text = existingReview;
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.movieTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Your rating: ${_rating == 0 ? "?" : _rating}/10',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 2,
                children: List.generate(10, (i) {
                  final star = i + 1;
                  final filled = star <= _rating;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              const Text(
                'Review (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              TextField(
                controller: _controller,
                maxLines: 6,
                style: TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(color: Colors.black),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (_rating < 1 || _rating > 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a rating (1–10)',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _saving = true);
                              try {
                                final review = Review(
                                  movieId: widget.movieId,
                                  movieTitle: widget.movieTitle,
                                  posterPath: widget.posterPath,
                                  userId: widget.userId,
                                  userName: widget.userName,
                                  userPhoto: user?.photoURL,
                                  rating: _rating,
                                  review: _controller.text.trim().isEmpty
                                      ? null
                                      : _controller.text.trim(),
                                );

                                await widget.reviewService.upsertReview(
                                  widget.movieId,
                                  review,
                                );
                                if (mounted) Navigator.pop(context);
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: Text(exists ? 'Update' : 'Submit'),
                    ),
                  ),
                  if (exists) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                try {
                                  await widget.reviewService.deleteReview(
                                    widget.movieId,
                                    widget.userId,
                                  );
                                  if (mounted) Navigator.pop(context);
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
class FavoriteHeart extends StatelessWidget {
  final int movieId;
  final String posterPath;
  final double width;

  const FavoriteHeart({
    super.key,
    required this.movieId,
    required this.posterPath,
    this.width = 28,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(movieId.toString());

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        final isFavorite = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          onTap: () async {
            if (isFavorite) {
              await docRef.delete();
            } else {
              await docRef.set({
                'movieId': movieId,
                'posterPath': posterPath,
                'addedAt': FieldValue.serverTimestamp(),
              });
            }
          },
          child: Icon(
            Icons.favorite,
            size: width,
            color: isFavorite ? Colors.redAccent : Colors.white38,
          ),
        );
      },
    );
  }
}
