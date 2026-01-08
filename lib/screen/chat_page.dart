import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import '../widgets/nav_helpers.dart';
import 'chats_page.dart';

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
    navigateWithSlide(
      context: context,
      current: MoviqBottomTab.chat,
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
