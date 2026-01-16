import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moviq/screen/chats_page.dart';
import '../widgets/moviq_scaffold.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'movie_details_page.dart';
import '../config/tmdb_config.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return MoviqScaffold(
        currentTopTab: MoviqTopTab.films,
        currentBottomTab: MoviqBottomTab.favorites,
        showTopNav: false,
        onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
        body: const Center(
          child: Text(
            'Please log in to see favorites',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.favorites,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Column(
        children: [
          // Pink oval "Favorites ❤️"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A3A3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Favorites ❤️',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // White line below the oval
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            color: Colors.white,
          ),

          // Expanded favorites grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No favorite movies yet',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    itemCount: docs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final movie = docs[index].data() as Map<String, dynamic>;
                      final movieId = int.tryParse(docs[index].id) ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailsPage(movieId: movieId),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                TmdbConfig.imageBaseUrl +
                                    (movie['posterPath'] ?? ''),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              // Heart to remove from favorites
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => _removeFromFavorites(
                                      user.uid, movieId.toString()),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Centered floating heart+ button above bottom nav
          Positioned(
            bottom: 20, // slightly above nav
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddFavoritePage()),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    // Heart-shaped button
                    Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    // Plus in the center
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    switch (tab) {
      case MoviqBottomTab.dashboard:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case MoviqBottomTab.search:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
        break;
      case MoviqBottomTab.chat:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
        break;
      case MoviqBottomTab.chats:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatsPage()),
        );
        break;
      case MoviqBottomTab.favorites:
        break;
      case MoviqBottomTab.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  /// Remove movie from favorites
  Future<void> _removeFromFavorites(String uid, String movieId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(movieId)
        .delete();
  }
}

/// ==========================================================
/// AddFavoritePage - search & add to favorites
/// ==========================================================
class AddFavoritePage extends StatefulWidget {
  const AddFavoritePage({super.key});

  @override
  State<AddFavoritePage> createState() => _AddFavoritePageState();
}

class _AddFavoritePageState extends State<AddFavoritePage> {
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
        title: const Text('Add Favorite'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
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
            ),
          ),

          // Results
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
    );
  }

  Widget _movieRow(Movie movie) {
    final posterUrl = movie.posterPath.isEmpty
        ? null
        : '${TmdbConfig.imageBaseUrl}${movie.posterPath}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Add to favorites
          IconButton(
            icon: const Icon(Icons.favorite, color: _pink),
            onPressed: () => _addToFavorites(movie),
          ),
        ],
      ),
    );
  }

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

  Future<void> _addToFavorites(Movie movie) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(movie.id.toString())
        .set({
      'movieId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'genreIds': movie.genreIds, 
      'addedAt': FieldValue.serverTimestamp(),
    });
    
    await FirebaseFirestore.instance
         .collection('users')
         .doc(user.uid)
         .collection('interactions')
         .add({
      'movieId': movie.id,
      'genreIds': movie.genreIds,
      'weight': 3,
      'source': 'favorite',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${movie.title} added to favorites'),
        backgroundColor: _pink,
      ),
    );
  }
}
