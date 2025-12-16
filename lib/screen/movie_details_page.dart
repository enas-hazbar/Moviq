import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../config/tmdb_config.dart';
import '../models/movie.dart';
import '../widgets/trailer_player.dart';
import 'actor_details_page.dart';
class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final TmdbService _service = TmdbService();

  late Future<Map<String, dynamic>> _movie;
  late Future<List<dynamic>> _videos;
  late Future<Map<String, dynamic>> _credits;
  late Future<Map<String, dynamic>> _providers;
  late Future<List<Movie>> _similar;

  @override
  void initState() {
    super.initState();
    _movie = _service.getMovieDetails(widget.movieId);
    _videos = _service.getMovieVideos(widget.movieId);
    _credits = _service.getCredits(widget.movieId);
    _providers = _service.getWatchProviders(widget.movieId);
    _similar = _service.getSimilarMovies(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Movie Details')),
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
                /// POSTER
                Image.network(
                  TmdbConfig.imageBaseUrl + movie['poster_path'],
                ),

                const SizedBox(height: 16),

                /// TITLE
                Text(
                  movie['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '⭐ ${movie['vote_average']}',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                /// GENRES
                Wrap(
                  spacing: 8,
                  children: (movie['genres'] as List)
                      .map((g) => Chip(label: Text(g['name'])))
                      .toList(),
                ),

                const SizedBox(height: 16),

                /// OVERVIEW
                Text(
                  movie['overview'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 24),

                /// TRAILER
                _buildTrailer(),

                const SizedBox(height: 24),

                /// WHERE TO WATCH
                _buildProviders(),

                const SizedBox(height: 24),

                /// CAST (CLICKABLE)
                _buildCast(),

                const SizedBox(height: 24),

                /// SIMILAR MOVIES
                _buildSimilarMovies(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🎬 TRAILER
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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TrailerPlayer(youtubeKey: trailer['key']),
          ],
        );
      },
    );
  }

  /// WHERE TO WATCH
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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
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

  /// 🎭 CAST → ACTOR DETAILS
  Widget _buildCast() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _credits,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final cast = (snapshot.data!['cast'] as List).take(8);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cast',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                          builder: (_) => ActorDetailsPage(
                            personId: actor['id'],
                          ),
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
                                ? NetworkImage(
                                    TmdbConfig.imageBaseUrl + actor['profile_path'],
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            actor['name'],
                            style: const TextStyle(color: Colors.white),
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

  /// 🎞️ SIMILAR MOVIES → MOVIE DETAILS
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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                          builder: (_) => MovieDetailsPage(
                            movieId: movie.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
