import 'package:flutter/material.dart';

enum MoviqTopTab { films, reviews, friends, list }
enum MoviqBottomTab { dashboard, search, chat, favorites, profile }

class MoviqScaffold extends StatelessWidget {
  const MoviqScaffold({
    super.key,
    required this.body,
    this.currentTopTab = MoviqTopTab.films,
    this.currentBottomTab = MoviqBottomTab.dashboard,
    this.onTopTabSelected,
    this.onBottomTabSelected,
    this.showTopNav = true,
  });

  final Widget body;
  final MoviqTopTab currentTopTab;
  final MoviqBottomTab currentBottomTab;
  final ValueChanged<MoviqTopTab>? onTopTabSelected;
  final ValueChanged<MoviqBottomTab>? onBottomTabSelected;
  final bool showTopNav;

  static const Color _background = Colors.black;
  static const Color _pink = Color(0xFFE5A3A3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MoviqHeader(),
            if (showTopNav)
              _TopNav(
                activeTab: currentTopTab,
                onSelected: onTopTabSelected,
              ),
            Expanded(child: body),
            _BottomNav(
              activeTab: currentBottomTab,
              onSelected: onBottomTabSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoviqHeader extends StatelessWidget {
  const _MoviqHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9E6E5), width: 2),
        ),
      ),
      child: const Center(
        child: Text(
          'M O V I Q',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: 7.5,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.activeTab,
    required this.onSelected,
  });

  final MoviqTopTab activeTab;
  final ValueChanged<MoviqTopTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (MoviqTopTab.films, 'Films'),
      (MoviqTopTab.reviews, 'Reviews'),
      (MoviqTopTab.friends, 'Friends'),
      (MoviqTopTab.list, 'List'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9E6E5), width: 2),
        ),
      ),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Expanded(
              child: InkWell(
                onTap: onSelected == null ? null : () => onSelected!(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: tab == activeTab ? MoviqScaffold._pink : Colors.transparent,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.activeTab,
    required this.onSelected,
  });

  final MoviqBottomTab activeTab;
  final ValueChanged<MoviqBottomTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    const entries = [
      (MoviqBottomTab.dashboard, 'assets/dashboard.png'),
      (MoviqBottomTab.search, 'assets/search.png'),
      (MoviqBottomTab.chat, 'assets/chatbot.png'),
      (MoviqBottomTab.favorites, 'assets/favorites.png'),
      (MoviqBottomTab.profile, 'assets/profile.png'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (tab, asset) in entries)
              _BottomIcon(
                assetPath: asset,
                isActive: tab == activeTab,
                onTap: onSelected == null ? null : () => onSelected!(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.assetPath,
    required this.isActive,
    this.onTap,
  });

  final String assetPath;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = 32.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? MoviqScaffold._pink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          color: Colors.white,
        ),
      ),
    );
  }
}
