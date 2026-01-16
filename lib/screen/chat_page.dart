import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../widgets/moviq_scaffold.dart';
import '../widgets/nav_helpers.dart';

import 'home_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();

  String? _chatId;
  bool _sending = false;
  String _streamingText = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final id = await _chatService.getOrCreateChat();
    if (!mounted) return;
    setState(() {
      _chatId = id;
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _chatId == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _sending = true;
      _streamingText = '';
    });

    await _chatService.sendUserMessage(_chatId!, text);

    final buffer = StringBuffer();
    await for (final chunk in _chatService.streamAssistantResponse(text)) {
      buffer.write(chunk);
      if (!mounted) return;
      setState(() {
        _streamingText = buffer.toString();
      });
    }

    await _chatService.saveAssistantMessage(
      _chatId!,
      buffer.toString(),
    );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _streamingText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MoviqScaffold(
      showTopNav: false,
      currentBottomTab: MoviqBottomTab.chat,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.messageStream(_chatId!),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final doc in docs)
                      _MessageBubble(
                        text: doc['content'],
                        isUser: doc['role'] == 'user',
                      ),
                    if (_streamingText.isNotEmpty)
                      _MessageBubble(
                        text: _streamingText,
                        isUser: false,
                        streaming: true,
                      ),
                  ],
                );
              },
            ),
          ),
          _inputBar(),
        ],
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
      case MoviqBottomTab.favorites:
        return const FavoritesPage();
      case MoviqBottomTab.profile:
        return const ProfilePage();
    }
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool streaming;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.streaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE5A3A3) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontStyle: streaming ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
