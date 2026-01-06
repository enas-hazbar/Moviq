import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class AddMovieToListPage extends StatefulWidget {
  final String listId;
  final String listName;

  const AddMovieToListPage({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<AddMovieToListPage> createState() => _AddMovieToListPageState();
}

class _AddMovieToListPageState extends State<AddMovieToListPage> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _controller = TextEditingController();

  List<Movie> _results = [];
  bool _loading = false;

  static const Color _pink = Color(0xFFE5A3A3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Add to ${widget.listName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchField(),
            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
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
    );
  }

  // 🔍 Search field
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

  // 🎬 Movie row
  Widget _movieRow(Movie movie) {
    final posterUrl = movie.posterPath.isEmpty
        ? null
        : '${TmdbConfig.imageBaseUrl}${movie.posterPath}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
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

          Expanded(
            child: Text(
              movie.title,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.add, color: _pink),
            onPressed: () => _addToList(movie),
          ),
        ],
      ),
    );
  }

  // 🔎 Search logic
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

  // ⭐ Add movie to list
  Future<void> _addToList(Movie movie) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .doc(movie.id.toString()) // prevents duplicates
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
        content: Text('${movie.title} added to ${widget.listName}'),
        backgroundColor: _pink,
      ),
    );
  }
}
