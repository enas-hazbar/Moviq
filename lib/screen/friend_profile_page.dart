import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import '../widgets/nav_helpers.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/recently_viewed_list.dart';
import 'chats_page.dart';

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
          final coverPhoto = data?['coverPhotoUrl'] as String?;

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
                _FriendHeader(
                  coverPhotoUrl: coverPhoto,
                  photoUrl: displayPhoto,
                ),
                const SizedBox(height: 42),
                const _SectionHeader(title: 'Favourites:'),
                const SizedBox(height: 16),
                const SizedBox(height: 140),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Recent Activity:'),
                const SizedBox(height: 16),
                RecentActivityList(userId: userId),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Recently Viewed:'),
                const SizedBox(height: 12),
                RecentlyViewedList(userId: userId),
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
      case MoviqBottomTab.chats:
          return const ChatsPage();  
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

class _FriendHeader extends StatelessWidget {
  const _FriendHeader({
    required this.coverPhotoUrl,
    required this.photoUrl,
  });

  final String? coverPhotoUrl;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _FriendCover(coverPhotoUrl: coverPhotoUrl),
          Positioned(
            left: 16,
            bottom: -18,
            child: _FriendAvatar(photoUrl: photoUrl),
          ),
        ],
      ),
    );
  }
}

class _FriendCover extends StatelessWidget {
  const _FriendCover({required this.coverPhotoUrl});

  final String? coverPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasUrl)
              Image.network(
                coverPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _coverPlaceholder(),
              )
            else
              _coverPlaceholder(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0E0E0E)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white38, size: 28),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.black,
        backgroundImage:
            (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
        child: (photoUrl == null || photoUrl!.isEmpty)
            ? const Icon(Icons.person, color: Colors.white, size: 48)
            : null,
      ),
    );
  }
}
