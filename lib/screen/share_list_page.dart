import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chats_service.dart'; 
class ShareListPage extends StatelessWidget {
  final String listType; 
  final String listName;
  final String? listId;  

  const ShareListPage({
    super.key,
    required this.listType,
    required this.listName,
    this.listId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Share with')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('friends')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snap.data!.docs;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (_, i) {
              final friend = friends[i];
              final name = friend['username'];

              return ListTile(
                title: Text(name),
                trailing: const Icon(Icons.send),
                onTap: () async {
                  await ChatsService().sendList(
                    otherUid: friend.id,
                    listType: listType,
                    listId: listId, 
                    listName: listName,
                  );

                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
