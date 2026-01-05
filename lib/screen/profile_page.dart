import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/moviq_scaffold.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import '../widgets/nav_helpers.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _pink = Color(0xFFE5A3A3);
  static const TextStyle _sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      slideRoute(page: const SettingsPage(), fromRight: true),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: _ProfileAvatar()),
            const SizedBox(height: 28),

            // My Faves
            const _SectionHeader(title: 'My Faves:'),
            const SizedBox(height: 16),
            const SizedBox(height: 140),
            const SizedBox(height: 28),

            // Recent Activity
            const _SectionHeader(title: 'Recent Activity:'),
            const SizedBox(height: 16),
            const SizedBox(height: 160),
            const SizedBox(height: 28),

            // Friend List
            const _SectionHeader(title: 'Friend List:'),
            const SizedBox(height: 12),
            const SizedBox(height: 60),
          ],
        ),
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
    return Text(title, style: ProfilePage._sectionTitle);
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _AvatarShell(
        child: Icon(Icons.person, color: Colors.white, size: 48),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final firestoreUrl = data?['photoUrl'] as String?;
        final photoUrl = (firestoreUrl != null && firestoreUrl.isNotEmpty)
            ? firestoreUrl
            : user.photoURL;

        if (photoUrl == null || photoUrl.isEmpty) {
          return const _AvatarShell(
            child: Icon(Icons.person, color: Colors.white, size: 48),
          );
        }

        return _AvatarShell(
          imageProvider: NetworkImage(photoUrl),
        );
      },
    );
  }
}

class _AvatarShell extends StatelessWidget {
  const _AvatarShell({this.imageProvider, this.child});

  final ImageProvider? imageProvider;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.black,
        backgroundImage: imageProvider,
        child: child,
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.movie, color: Colors.white54, size: 36),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.placeholders});

  final List<_PosterPlaceholder> placeholders;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final poster in placeholders) ...[
          poster,
          const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.title,
    required this.subtitle,
    this.poster,
  });

  final String title;
  final String subtitle;
  final Widget? poster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poster ??
              Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported, color: Colors.white54),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.name,
    this.showButton = true,
  });

  final String name;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const Spacer(),
        if (showButton)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ProfilePage._pink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
