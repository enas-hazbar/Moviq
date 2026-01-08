import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import '../config/tmdb_config.dart';
class SharedListDetailsPage extends StatelessWidget {
  final String ownerId;
  final String listId;
  final String listName;

  const SharedListDetailsPage({
    super.key,
    required this.ownerId,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .collection('lists')
            .doc(listId)
            .collection('items')
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text('List is empty'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final data = items[i].data() as Map<String, dynamic>;
              final poster = data['posterPath'];

              return Image.network(
                '${TmdbConfig.imageBaseUrl}$poster',
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}
