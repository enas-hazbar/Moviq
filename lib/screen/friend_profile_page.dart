import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import '../widgets/nav_helpers.dart';
import '../config/tmdb_config.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'search_page.dart';

class FriendProfilePage extends StatelessWidget {
  const FriendProfilePage({
    super.key,
    required this.userId,
    required this.username,
    required this.photoUrl,
  });

  final String userId;
  final String username;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .handleError((_) {}),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final displayName = (data?['username'] as String?) ?? username;
          final displayPhoto = (data?['photoUrl'] as String?) ?? photoUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                      backgroundImage: (displayPhoto != null && displayPhoto!.isNotEmpty)
                          ? NetworkImage(displayPhoto!)
                          : null,
                      child: (displayPhoto == null || displayPhoto!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white, size: 48)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Favourites:'),
                const SizedBox(height: 16),
                const SizedBox(height: 140),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Recent Activity:'),
                const SizedBox(height: 16),
                _FriendRecentActivityList(userId: userId),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    navigateWithSlide(
      context: context,
      current: MoviqBottomTab.profile,
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }
}

class _FriendRecentActivityList extends StatelessWidget {
  const _FriendRecentActivityList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80);
        }
        if (snapshot.hasError) {
          return const Text(
            'Unable to load recent activity.',
            style: TextStyle(color: Colors.white70),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No recent activity yet.',
            style: TextStyle(color: Colors.white70),
          );
        }
        return Column(
          children: [
            for (final doc in docs)
              _FriendRecentReviewRow(data: doc.data() as Map<String, dynamic>),
          ],
        );
      },
    );
  }
}

class _FriendRecentReviewRow extends StatelessWidget {
  const _FriendRecentReviewRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String reviewText = (data['review'] as String?) ?? '';
    final int rating10 = (data['rating'] as num?)?.toInt() ?? 0;
    final int starRating = ((rating10 / 2).ceil()).clamp(0, 5);
    final String movieTitle = (data['movieTitle'] as String?) ?? 'Unknown movie';
    final String posterPath = (data['posterPath'] as String?) ?? '';

    final posterUrl =
        posterPath.isEmpty ? null : '${TmdbConfig.imageBaseUrl}$posterPath';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: posterUrl == null
                ? Container(
                    width: 60,
                    height: 84,
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: Colors.white38,
                      size: 22,
                    ),
                  )
                : Image.network(
                    posterUrl,
                    width: 60,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 84,
                      color: Colors.white12,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
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
                        size: 16,
                        color: const Color(0xFFB37C78),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$rating10/10',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reviewText.trim().isEmpty ? 'Rating only' : reviewText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  movieTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
