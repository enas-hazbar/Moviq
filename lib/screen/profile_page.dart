import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'splash_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Log out'),
          ),
        ),
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
      case MoviqBottomTab.favorites:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesPage()),
        );
        break;
      case MoviqBottomTab.profile:
        break;
    }
  }
}
