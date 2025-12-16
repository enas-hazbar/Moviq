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
  final TmdbService _service = TmdbService();

  late Future<List<Movie>> _popularMovies;
  late Future<List<Movie>> _upcomingMovies;

  bool _showAllPopular = false;
  bool _showAllUpcoming = false;

  @override
  void initState() {
    super.initState();
    _popularMovies = _service.getTrendingMovies();
    _upcomingMovies = _service.getUpcomingMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'MOVIQ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Section(
              title: 'Popular This Week',
              future: _popularMovies,
              showAll: _showAllPopular,
              onToggle: () {
                setState(() {
                  _showAllPopular = !_showAllPopular;
                });
              },
            ),
            const SizedBox(height: 32),
            _Section(
              title: 'Upcoming Movies',
              future: _upcomingMovies,
              showAll: _showAllUpcoming,
              onToggle: () {
                setState(() {
                  _showAllUpcoming = !_showAllUpcoming;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.future,
    required this.showAll,
    required this.onToggle,
  });

  final String title;
  final Future<List<Movie>> future;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              icon: Icon(
                showAll ? Icons.expand_less : Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 18,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Movie>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final movies = snapshot.data!;
            final visibleMovies =
                showAll ? movies : movies.take(6).toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleMovies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2 / 3,
              ),
              itemBuilder: (context, index) {
                final movie = visibleMovies[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MovieDetailsPage(movieId: movie.id),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            TmdbConfig.imageBaseUrl + movie.posterPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
