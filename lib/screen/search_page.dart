import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'movie_details_page.dart';

import '../widgets/moviq_scaffold.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TmdbService _service = TmdbService();
  final TextEditingController _controller = TextEditingController();

  List<Movie> _results = [];
  Map<int, String> _genres = {};
  Map<int, bool> _expandedDecades = {};

  int? _selectedGenre;
  double? _selectedRating;
  int? _startYear;
  int? _endYear;

  bool _filtersOpen = false;
  bool _genreOpen = false;
  bool _decadeOpen = false;
  bool _ratingOpen = false;

  bool _loading = false;
  List<String> _history = [];
  bool _showHistory = false;

  static const Color _pink = Color(0xFFE5A3A3);

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadSearchHistory();
  }

  // =========================
  // 🔥 FIXED: AUTH-AWARE UID
  // =========================
  Future<void> _loadSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('search_history')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    setState(() {
      _history = snapshot.docs.map((d) => d.id).toList();
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('search_history')
        .doc(term)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    _loadSearchHistory();
  }

  Future<void> _loadGenres() async {
    _genres = await _service.getGenres();
    setState(() {});
  }

  Future<void> _search() async {
    setState(() => _loading = true);

    if (_controller.text.isNotEmpty) {
      _results = await _service.searchMovies(_controller.text);
      await _saveSearchTerm(_controller.text);
    } else {
      _results = await _service.discoverMovies(
        startYear: _startYear,
        endYear: _endYear,
        genreId: _selectedGenre,
        minRating: _selectedRating,
      );
    }

    setState(() => _loading = false);
  }

  void _clearAll() {
    setState(() {
      _controller.clear();
      _selectedGenre = null;
      _selectedRating = null;
      _startYear = null;
      _endYear = null;
      _results = [];
      _showHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.search,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchHeader(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _filtersHeader(),
                if (_filtersOpen) _buildFilters(),
                const SizedBox(height: 12),
                _buildResults(),
              ],
            ),
          ),

          if (_showHistory && _controller.text.isEmpty)
            Positioned(
              top: 180,
              left: 16,
              right: 16,
              child: Material(
                color: _pink,
                borderRadius: BorderRadius.circular(12),
                child: ListView(
                  shrinkWrap: true,
                  children: _history.map((h) {
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.white),
                      title: Text(h,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        setState(() {
                          _controller.text = h;
                          _showHistory = false;
                        });
                        _search();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= UI PARTS =================

  Widget _searchHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: _pink,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white),
                SizedBox(width: 8),
                Text('Search',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search movies...',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: _pink,
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: () {
        if (_controller.text.isEmpty) {
          setState(() => _showHistory = true);
        }
      },
      onChanged: (value) {
        setState(() => _showHistory = value.isEmpty);
        if (value.length > 2) _search();
      },
    );
  }

  Widget _filtersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _filtersOpen = !_filtersOpen),
          child: Row(
            children: [
              const Text('Filters',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Icon(
                _filtersOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear, color: Colors.white),
          label:
              const Text('Clear All', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'Release decade',
          _decadeOpen,
          () => setState(() => _decadeOpen = !_decadeOpen),
          _buildDecades(),
        ),
        _buildSection(
          'Genre',
          _genreOpen,
          () => setState(() => _genreOpen = !_genreOpen),
          _buildGenres(),
        ),
        _buildSection(
          'Rating',
          _ratingOpen,
          () => setState(() => _ratingOpen = !_ratingOpen),
          _buildRatings(),
        ),
      ],
    );
  }

  Widget _buildSection(
      String title, bool open, VoidCallback onTap, Widget content) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Icon(
                open
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (open) content,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDecades() => const SizedBox(); // senin mevcut hali korunabilir
  Widget _buildGenres() => const SizedBox();
  Widget _buildRatings() => const SizedBox();

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) return const SizedBox();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final movie = _results[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailsPage(movieId: movie.id),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              TmdbConfig.imageBaseUrl + movie.posterPath,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    if (tab == MoviqBottomTab.dashboard) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
    if (tab == MoviqBottomTab.chat) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ChatPage()));
    }
    if (tab == MoviqBottomTab.favorites) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
    }
    if (tab == MoviqBottomTab.profile) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }
}
