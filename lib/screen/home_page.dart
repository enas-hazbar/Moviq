import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../config/tmdb_config.dart';
import 'movie_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TmdbService _tmdbService = TmdbService();
  late Future<List<Movie>> _movies;

  @override
  void initState() {
    super.initState();
    _movies = _tmdbService.getPopularMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MOVIQ'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Movie>>(
        future: _movies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
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
                title: Text(movie.title),
                subtitle: Text('⭐ ${movie.rating}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MovieDetailsPage(movieId: movie.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
