import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadSearchHistory();
  }

  Future<void> _loadGenres() async {
    _genres = await _service.getGenres();
    setState(() {});
  }

  Future<void> _loadSearchHistory() async {
    final userId = 'CURRENT_USER_ID'; // replace with real user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
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

    final userId = 'CURRENT_USER_ID'; // replace with real user ID
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('search_history');

    await docRef.doc(term).set({'timestamp': FieldValue.serverTimestamp()});
    _loadSearchHistory();
  }

  Future<void> _search() async {
    setState(() => _loading = true);

    if (_controller.text.isNotEmpty) {
      _results = await _service.searchMovies(_controller.text);
      _saveSearchTerm(_controller.text);
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
                const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔍 SEARCH BAR
                _buildSearchBar(),

                const SizedBox(height: 12),

                // 🔽 FILTER HEADER RIGHT UNDER SEARCH BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _filtersOpen = !_filtersOpen);
                      },
                      child: Row(
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _filtersOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear, color: Colors.white),
                      label: const Text('Clear All',
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),

                if (_filtersOpen) _buildFilters(), // ⚡ Filters appear here

                const SizedBox(height: 12),

                /// 🎬 RESULTS BELOW FILTERS
                _buildResults(),
              ],
            ),
          ),

          // 🔽 GOOGLE-STYLE HISTORY DROPDOWN
          if (_showHistory && _controller.text.isEmpty)
            Positioned(
              top: 100, // adjust according to your layout
              left: 16,
              right: 16,
              child: Material(
                color: const Color(0xFFB47A78),
                borderRadius: BorderRadius.circular(12),
                child: ListView(
                  shrinkWrap: true,
                  children: _history
                      .map(
                        (h) => ListTile(
                          title: Text(h,
                              style: const TextStyle(color: Colors.white)),
                          leading:
                              const Icon(Icons.history, color: Colors.white),
                          onTap: () {
                            setState(() {
                              _controller.text = h;
                              _showHistory = false;
                            });
                            _search();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
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
        fillColor: const Color(0xFFB47A78),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _showHistory = value.isEmpty;
        });
        if (value.length > 2) _search();
      },
      onTap: () {
        if (_controller.text.isEmpty) setState(() => _showHistory = true);
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSection(
          title: 'Release decade',
          isOpen: _decadeOpen,
          onTap: () => setState(() => _decadeOpen = !_decadeOpen),
          content: _buildDecades(),
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'Genre',
          isOpen: _genreOpen,
          onTap: () => setState(() => _genreOpen = !_genreOpen),
          content: _buildGenres(),
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'Rating',
          isOpen: _ratingOpen,
          onTap: () => setState(() => _ratingOpen = !_ratingOpen),
          content: _buildRatings(),
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title,
      required bool isOpen,
      required VoidCallback onTap,
      required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (isOpen) content,
      ],
    );
  }

  // 📅 DECADES
  Widget _buildDecades() {
  final decades = [
    {'label': '2020s', 'start': 2020, 'end': 2029},
    {'label': '2010s', 'start': 2010, 'end': 2019},
    {'label': '2000s', 'start': 2000, 'end': 2009},
    {'label': '1990s', 'start': 1990, 'end': 1999},
    {'label': '1980s', 'start': 1980, 'end': 1989},
    {'label': '1970s', 'start': 1970, 'end': 1979},
    {'label': '1960s', 'start': 1960, 'end': 1969},
    {'label': '1950s', 'start': 1950, 'end': 1959},
  ];

  return Column(
    children: decades.map((d) {
      final start = d['start'] as int;
      final end = d['end'] as int;
      final label = d['label'] as String;
      final isExpanded = _expandedDecades[start] ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decade row with arrow
          ListTile(
            title: Text(label, style: const TextStyle(color: Colors.white)),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onTap: () {
              setState(() {
                // toggle expanded state
                _expandedDecades[start] = !isExpanded;
                // select entire decade
                _startYear = start;
                _endYear = end;
              });
              _search();
            },
          ),

          // Expanded exact years
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: List.generate(end - start + 1, (index) {
                  final year = start + index;
                  return RadioListTile(
                    value: year,
                    groupValue: _startYear == _endYear ? _startYear : null,
                    onChanged: (_) {
                      setState(() {
                        _startYear = year;
                        _endYear = year;
                      });
                      _search();
                    },
                    title: Text(year.toString(),
                        style: const TextStyle(color: Colors.white70)),
                    activeColor: Colors.pinkAccent,
                  );
                }),
              ),
            ),
        ],
      );
    }).toList(),
  );
}

  // 🎭 GENRES
  Widget _buildGenres() {
    if (_genres.isEmpty) {
      return const Text(
        'Loading genres...',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: _genres.entries.map((g) {
        return RadioListTile(
          value: g.key,
          groupValue: _selectedGenre,
          onChanged: (v) {
            setState(() => _selectedGenre = v);
            _search();
          },
          title: Text(g.value, style: const TextStyle(color: Colors.white)),
          activeColor: Colors.pinkAccent,
        );
      }).toList(),
    );
  }

  // ⭐ RATINGS
  Widget _buildRatings() {
    return Column(
      children: [
        _ratingOption('4★ & Up', 8.0),
        _ratingOption('3★ & Up', 6.0),
      ],
    );
  }

  Widget _ratingOption(String label, double value) {
    return RadioListTile(
      value: value,
      groupValue: _selectedRating,
      onChanged: (v) {
        setState(() => _selectedRating = v);
        _search();
      },
      title: Text(label, style: const TextStyle(color: Colors.white)),
      activeColor: Colors.pinkAccent,
    );
  }

  // ================= RESULTS =================
  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_results.isEmpty) {
      return const SizedBox();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final movie = _results[index];
        if (movie.posterPath.isEmpty) return const SizedBox();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailsPage(movieId: movie.id),
              ),
            );
          },
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

  // ================= NAV =================
  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    switch (tab) {
      case MoviqBottomTab.dashboard:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case MoviqBottomTab.search:
        break;
      case MoviqBottomTab.chat:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
        break;
      case MoviqBottomTab.favorites:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesPage()),
        );
        break;
      case MoviqBottomTab.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }
}
