import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/moviq_scaffold.dart';
import '../config/tmdb_config.dart';
import 'home_page.dart';
import 'movie_details_page.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'reviews_page.dart';
import 'watchlist_page.dart';
import '../widgets/nav_helpers.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int? _selectedRating10;

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
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Please sign in', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final friendsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots()
        .handleError((_) {});

    return MoviqScaffold(
      currentTopTab: MoviqTopTab.friends,
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
        if (tab == MoviqTopTab.list) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WatchlistPage()),
          );
        }
      },
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: friendsStream,
              builder: (context, friendsSnap) {
                if (friendsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friendIds = friendsSnap.data?.docs.map((d) => d.id).toSet() ?? {};
                if (friendIds.isEmpty) {
                  return const Center(
                    child: Text(
                      'No friend activity yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('reviews')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final friendDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = data['userId'] as String?;
                      return userId != null && friendIds.contains(userId);
                    }).toList();

                    final filteredDocs = _selectedRating10 == null
                        ? friendDocs
                        : friendDocs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final rating = (data['rating'] as num?)?.toInt() ?? 0;
                            return rating == _selectedRating10;
                          }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No friend reviews yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index].data() as Map<String, dynamic>;

                        final String? userId = data['userId'] as String?;
                        final String reviewText = (data['review'] as String?) ?? '';
                        final int rating10 = (data['rating'] as num?)?.toInt() ?? 0;
                        final int starRating = ((rating10 / 2).ceil()).clamp(0, 5);
                        final String movieTitle =
                            (data['movieTitle'] as String?) ?? 'Unknown movie';
                        final int? movieId = (data['movieId'] as num?)?.toInt();
                        final String posterPath = (data['posterPath'] as String?) ?? '';

                        if (userId == null || userId.isEmpty) {
                          return _ReviewTile(
                            userName: 'Unknown',
                            userPhoto: null,
                            movieTitle: movieTitle,
                            reviewText: reviewText,
                            rating10: rating10,
                            starRating: starRating,
                            posterPath: posterPath,
                            onTap: movieId == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MovieDetailsPage(movieId: movieId),
                                      ),
                                    );
                                  },
                          );
                        }

                        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .snapshots(),
                          builder: (context, userSnap) {
                            final userData = userSnap.data?.data();
                            final liveUserName =
                                (userData?['username'] as String?) ??
                                (data['userName'] as String?) ??
                                'User';
                            final liveUserPhoto =
                                (userData?['photoUrl'] as String?) ??
                                (data['userPhoto'] as String?) ??
                                '';

                            return _ReviewTile(
                              userName: liveUserName,
                              userPhoto: liveUserPhoto.isEmpty ? null : liveUserPhoto,
                              movieTitle: movieTitle,
                              reviewText: reviewText,
                              rating10: rating10,
                              starRating: starRating,
                              posterPath: posterPath,
                              onTap: movieId == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MovieDetailsPage(movieId: movieId),
                                        ),
                                      );
                                    },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          const Text(
            'Recent reviews of friends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _FilterButton(
                label: _selectedRating10 == null
                    ? 'Filter'
                    : 'Filter: $_selectedRating10/10',
                onPressed: () async {
                  final picked = await _openRatingFilterSheet(
                    context,
                    _selectedRating10,
                  );
                  if (!mounted) return;
                  setState(() => _selectedRating10 = picked);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _openRatingFilterSheet(
    BuildContext context,
    int? current,
  ) async {
    return showModalBottomSheet<int?>(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by rating (1–10)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _RatingChip(
                      label: 'All',
                      selected: current == null,
                      onTap: () => Navigator.pop(context, null),
                    ),
                    ...List.generate(10, (i) {
                      final value = i + 1;
                      return _RatingChip(
                        label: '$value',
                        selected: current == value,
                        onTap: () => Navigator.pop(context, value),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tip: Ratings are stored as /10, but shown as 5 stars.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String userName;
  final String? userPhoto;
  final String movieTitle;
  final String reviewText;
  final int rating10;
  final int starRating;
  final String posterPath;
  final VoidCallback? onTap;

  const _ReviewTile({
    required this.userName,
    required this.userPhoto,
    required this.movieTitle,
    required this.reviewText,
    required this.rating10,
    required this.starRating,
    required this.posterPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white12,
                  backgroundImage: (userPhoto != null && userPhoto!.isNotEmpty)
                      ? NetworkImage(userPhoto!)
                      : null,
                  child: (userPhoto == null || userPhoto!.isEmpty)
                      ? const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.white54,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Poster(posterPath: posterPath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < starRating ? Icons.star : Icons.star_border,
                              size: 18,
                              color: const Color(0xFFB37C78),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rating10/10',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reviewText.trim().isEmpty ? 'Rating only' : reviewText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              movieTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final String posterPath;
  const _Poster({required this.posterPath});

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterPath.isNotEmpty;
    final url = hasPoster ? '${TmdbConfig.imageBaseUrl}$posterPath' : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: url == null
          ? _posterPlaceholder()
          : Image.network(
              url,
              width: 92,
              height: 132,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _posterPlaceholder(),
            ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 92,
      height: 132,
      color: Colors.white12,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, color: Colors.white38, size: 30),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FilterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFB37C78),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RatingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB37C78) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
