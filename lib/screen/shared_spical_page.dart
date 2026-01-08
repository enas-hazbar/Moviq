import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import '../config/tmdb_config.dart';
class SharedSpecialListPage extends StatelessWidget {
  final String ownerId;
  final String listType; // watchlist | watched
  final String listName;

  const SharedSpecialListPage({
    super.key,
    required this.ownerId,
    required this.listType,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    final orderField =
        listType == 'watched' ? 'watchedAt' : 'addedAt';

    return Scaffold(
      appBar: AppBar(title: Text(listName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .collection(listType)
            .orderBy(orderField, descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('List is empty'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final posterPath = data['posterPath'] ?? '';

              return Image.network(
                '${TmdbConfig.imageBaseUrl}$posterPath',
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}
