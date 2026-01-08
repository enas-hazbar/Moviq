import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import 'chat_room_page.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatService.myChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(
              child: Text('No chats yet', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data();
              final participants = List<String>.from(data['participants'] ?? []);
              final friendId = participants.firstWhere((id) => id != me);

              final unreadMap = (data['unread'] is Map) ? Map<String, dynamic>.from(data['unread']) : {};
              final int unreadCount = (unreadMap[me] as num?)?.toInt() ?? 0;

              final lastMessage = (data['lastMessage'] as String?) ?? '';
              final lastType = (data['lastMessageType'] as String?) ?? 'text';

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(friendId).snapshots(),
                builder: (_, userSnap) {
                  final u = userSnap.data?.data();
                  final name = (u?['username'] as String?) ?? 'User';
                  final photo = (u?['photoUrl'] as String?) ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white12,
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: photo.isEmpty
                          ? const Icon(Icons.person, color: Colors.white70)
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      lastType == 'image' ? '📷 Photo' : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A3A3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatRoomPage(friendId: friendId)),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
