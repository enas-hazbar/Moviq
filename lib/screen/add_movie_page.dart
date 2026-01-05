import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class AddMoviePage extends StatefulWidget {
  const AddMoviePage({super.key});

  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends State<AddMoviePage> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _controller = TextEditingController();

  List<Movie> _results = [];
  bool _loading = false;

  static const Color _pink = Color(0xFFE5A3A3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _searchField(),
                const SizedBox(height: 16),

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'Search for a movie',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                return _movieRow(_results[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔍 SEARCH FIELD
  Widget _searchField() {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchMovies(),
      decoration: InputDecoration(
        hintText: 'Search movie',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white12,
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _searchMovies,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 🎬 MOVIE ROW WITH ADD BUTTON
  Widget _movieRow(Movie movie) {
    final posterUrl = movie.posterPath.isEmpty
        ? null
        : '${TmdbConfig.imageBaseUrl}${movie.posterPath}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: posterUrl == null
                ? Container(
                    width: 40,
                    height: 60,
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.movie, color: Colors.white54),
                  )
                : Image.network(
                    posterUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              movie.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ➕ ADD BUTTON
          IconButton(
            icon: const Icon(Icons.add, color: _pink),
            onPressed: () => _addToWatchlist(movie),
          ),
        ],
      ),
    );
  }

  // 🔎 SEARCH LOGIC
  Future<void> _searchMovies() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);

    final movies = await _tmdbService.searchMovies(query);

    if (!mounted) return;
    setState(() {
      _results = movies;
      _loading = false;
    });
  }

  // ⭐ ADD TO WATCHLIST
  Future<void> _addToWatchlist(Movie movie) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .doc(movie.id.toString())
        .set({
      'movieId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'addedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
  Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${movie.title} added to watchlist'),
        backgroundColor: _pink,
      ),
    );
  }
}
