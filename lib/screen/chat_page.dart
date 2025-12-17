import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'home_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.chat,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: const Center(
        child: Text(
          'Chatbot coming soon',
          style: TextStyle(color: Colors.white, fontSize: 18),
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
        break;
      case MoviqBottomTab.favorites:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesPage()),
        );
        break;
      case MoviqBottomTab.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }
}
