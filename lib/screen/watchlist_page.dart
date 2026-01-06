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
import 'list_details_page.dart';
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
  
}

class _WatchlistPageState extends State<WatchlistPage> {
  bool showWatched = false;
Future<void> _removeFromWatched(
  BuildContext context,
  int movieId,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watched')
      .doc(movieId.toString())
      .delete();

if (!mounted) return;

ScaffoldMessenger.of(
  Navigator.of(context, rootNavigator: true).context,
).showSnackBar(
  const SnackBar(content: Text('Removed from watched')),
);
}
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
Future<void> _createListDialog() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final controller = TextEditingController();

  await showDialog(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'New List',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'List name (e.g. Horror)',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('lists')
                  .add({
                'name': name,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
            style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            foregroundColor: Colors.white,
            )
          ),
        ],
      );
    },
  );

}

  static const Color _pink = Color(0xFFE5A3A3);

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final uid = user.uid;

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

            if (!showWatched) _listsSection(uid),

            Expanded(
              child: showWatched
                  ? _buildGrid(uid, 'watched', 'watchedAt')
                  : _buildGrid(uid, 'watchlist', 'addedAt'),
            ),
          ],
        ),


          if (!showWatched)
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
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔀 Header toggle
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white24),
          bottom: BorderSide(color: Colors.white24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabButton(
            label: 'Watchlist',
            selected: !showWatched,
            onTap: () => setState(() => showWatched = false),
          ),
          const SizedBox(width: 12),
          _tabButton(
            label: 'Watched',
            selected: showWatched,
            onTap: () => setState(() => showWatched = true),
          ),
        ],
      ),
    );
  }
Widget _listsSection(String uid) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.black,
      border: Border(bottom: BorderSide(color: Colors.white24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Lists',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _createListDialog,
              icon: const Icon(Icons.add, size: 18, color: _pink),
              label: const Text('New', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _pink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('lists')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text(
                'No lists yet. Create one!',
                style: TextStyle(color: Colors.white54),
              );
            }

            return SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final name = (doc['name'] ?? 'List').toString();

                  return OutlinedButton(
                    onPressed: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ListDetailsPage(
                              listId: doc.id,
                              listName: name,
                            ),
                          ),
                        );
                      });
                    },

                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _pink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pink),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 📦 Shared grid for Watchlist + Watched
  Widget _buildGrid(String uid, String collection, String orderField) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(collection)
          .orderBy(orderField, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString(),
                style: const TextStyle(color: Colors.red)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              collection == 'watchlist'
                  ? 'Your watchlist is empty'
                  : 'No watched movies yet',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: docs.length,
         itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final int movieId = (data['movieId'] as num).toInt();
        final String posterPath = data['posterPath'] ?? '';

        final posterUrl = posterPath.isEmpty
            ? null
            : '${TmdbConfig.imageBaseUrl}$posterPath';

        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsPage(movieId: movieId),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                      ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (collection == 'watchlist') {
                    _removeFromWatchlist(context, movieId);
                  } else if (collection == 'watched') {
                    _removeFromWatched(context, movieId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
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
        );
      },
        );
      },
    );
  }
}
