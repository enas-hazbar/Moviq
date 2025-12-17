import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../services/review_service.dart';
import '../config/tmdb_config.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../widgets/trailer_player.dart';
import 'actor_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final TmdbService _tmdbService = TmdbService();
  final ReviewService _reviewService = ReviewService();

  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  late Future<Map<String, dynamic>> _movie;
  late Future<List<dynamic>> _videos;
  late Future<Map<String, dynamic>> _credits;
  late Future<Map<String, dynamic>> _providers;
  late Future<List<Movie>> _similar;

  @override
  void initState() {
    super.initState();
    _movie = _tmdbService.getMovieDetails(widget.movieId);
    _videos = _tmdbService.getMovieVideos(widget.movieId);
    _credits = _tmdbService.getCredits(widget.movieId);
    _providers = _tmdbService.getWatchProviders(widget.movieId);
    _similar = _tmdbService.getSimilarMovies(widget.movieId);
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  TmdbConfig.imageBaseUrl + movie['poster_path'],
                ),

                const SizedBox(height: 16),

                Text(
                  movie['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '⭐ TMDB ${movie['vote_average']}',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: (movie['genres'] as List)
                      .map((g) => Chip(label: Text(g['name'])))
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

                _buildReviewForm(),
                const SizedBox(height: 16),

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

  /// 🎬 Trailer
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
            const Text('Trailer',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            TrailerPlayer(youtubeKey: trailer['key']),
          ],
        );
      },
    );
  }

  /// 📺 Where to watch
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
            const Text('Where to watch',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (nl['flatrate'] as List)
                  .map((p) => Chip(label: Text(p['provider_name'])))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  /// 🎭 Cast
  Widget _buildCast() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _credits,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final cast = (snapshot.data!['cast'] as List).take(8);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cast',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: cast.map<Widget>((actor) {
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
                            backgroundImage: actor['profile_path'] != null
                                ? NetworkImage(TmdbConfig.imageBaseUrl +
                                    actor['profile_path'])
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(actor['name'],
                              style:
                                  const TextStyle(color: Colors.white)),
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

  /// ✍️ Review form
  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Review',
            style: TextStyle(color: Colors.white, fontSize: 18)),

        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _selectedRating
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() => _selectedRating = index + 1);
              },
            );
          }),
        ),

        TextField(
          controller: _reviewController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Write your review...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),

        ElevatedButton(
          onPressed: _submitReview,
          child: const Text('Submit Review'),
        ),
      ],
    );
  }

Future<void> _submitReview() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to submit a review'),
      ),
    );
    return;
  }

  if (_reviewController.text.trim().isEmpty) return;

  final review = Review(
    userId: user.uid,
    userName: user.email ?? 'User',
    rating: _selectedRating,
    review: _reviewController.text.trim(),
  );

  await _reviewService.addReview(widget.movieId, review);

  _reviewController.clear();
  setState(() => _selectedRating = 5);
}

  /// 🗨 Reviews list
  Widget _buildReviewsList() {
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

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              color: Colors.grey.shade900,
              child: ListTile(
                title: Text(data['userName'],
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['review'],
                    style: const TextStyle(color: Colors.white70)),
                trailing: Text(
                  '⭐ ${data['rating']}',
                  style: const TextStyle(color: Colors.amber),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 🎞 Similar movies
  Widget _buildSimilarMovies() {
    return FutureBuilder<List<Movie>>(
      future: _similar,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final movies = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Similar Movies',
                style: TextStyle(color: Colors.white, fontSize: 18)),
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
                          builder: (_) =>
                              MovieDetailsPage(movieId: movie.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.network(
                        TmdbConfig.imageBaseUrl + movie.posterPath,
                        width: 130,
                        fit: BoxFit.cover,
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
