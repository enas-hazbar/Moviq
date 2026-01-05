import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/moviq_scaffold.dart';
import '../config/tmdb_config.dart';
import 'movie_details_page.dart';
import 'home_page.dart';
import 'reviews_page.dart';
import 'friends_page.dart';
import 'add_movie_page.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import '../widgets/nav_helpers.dart';

class WatchlistPage extends StatelessWidget {
    void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    navigateWithSlide(
      context: context,
      current: MoviqBottomTab.dashboard,
      target: tab,
      builder: () => _pageForTab(tab),
    );
  }

  Widget _pageForTab(MoviqBottomTab tab) {
    switch (tab) {
      case MoviqBottomTab.dashboard:
        return const HomePage();
      case MoviqBottomTab.search:
        return const SearchPage();
      case MoviqBottomTab.chat:
        return const ChatPage();
      case MoviqBottomTab.favorites:
        return const FavoritesPage();
      case MoviqBottomTab.profile:
        return const ProfilePage();
    }
  }

  const WatchlistPage({super.key});

  static const Color _pink = Color(0xFFE5A3A3);

  Future<void> _removeFromWatchlist(
    BuildContext context,
    int movieId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(movieId.toString())
        .delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from watchlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MoviqScaffold(
      currentTopTab: MoviqTopTab.list,
      currentBottomTab: MoviqBottomTab.dashboard,
      showTopNav: true,
      onTopTabSelected: (tab) {
        if (tab == MoviqTopTab.films) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
        if (tab == MoviqTopTab.reviews) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ReviewsPage()),
          );
        }
        if (tab == MoviqTopTab.friends) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FriendsPage()),
          );
        }
      },
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Stack(
        children: [
          Column(
            children: [
              _header(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('watchlist')
                      .orderBy('addedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                          style:
                              const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Your watchlist is empty',
                          style:
                              TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;

                        final int movieId =
                            (data['movieId'] as num).toInt();
                        final String posterPath =
                            (data['posterPath'] as String?) ?? '';

                        final posterUrl = posterPath.isEmpty
                            ? null
                            : '${TmdbConfig.imageBaseUrl}$posterPath';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovieDetailsPage(
                                  movieId: movieId,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: posterUrl == null
                                    ? Container(
                                        color: Colors.white12,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.movie_outlined,
                                          color: Colors.white38,
                                          size: 30,
                                        ),
                                      )
                                    : Image.network(
                                        posterUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                Container(
                                          color: Colors.white12,
                                          alignment:
                                              Alignment.center,
                                          child: const Icon(
                                            Icons.movie_outlined,
                                            color: Colors.white38,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                              ),

                              // ❌ remove button
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  onTap: () => _removeFromWatchlist(
                                    context,
                                    movieId,
                                  ),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ➕ Add movie button
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  backgroundColor: _pink,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMoviePage(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: const Center(
        child: Text(
          'Watchlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
