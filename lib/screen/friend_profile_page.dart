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
