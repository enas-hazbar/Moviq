import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TmdbService _tmdbService = TmdbService();
  late Future<List<Movie>> _popularMovies;

  @override
  void initState() {
    super.initState();
    _popularMovies = _tmdbService.getPopularMovies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Movie>>(
      future: _popularMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final movies = snapshot.data!;

        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];

            return ListTile(
              leading: movie.posterPath.isNotEmpty
                  ? Image.network(
                      TmdbConfig.imageBaseUrl + movie.posterPath,
                      width: 50,
                    )
                  : null,
              title: Text(
                movie.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '⭐ ${movie.rating}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          },
        );
      },
    );
  }
}
