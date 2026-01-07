import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/tmdb_config.dart';

class PickFavoriteForSlotPage extends StatelessWidget {
  final String slotId;

  const PickFavoriteForSlotPage({
    super.key,
    required this.slotId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pick a Favorite'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load favorites',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No favorites yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.66,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final posterPath = data['posterPath'] as String? ?? '';
              final movieId = docs[index].id;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    debugPrint('Tapped poster for slot: $slotId');

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('profile_faves')
                          .doc(slotId)
                          .set({
                        'movieId': movieId,
                        'posterPath': posterPath,
                        'addedAt': FieldValue.serverTimestamp(),
                      });

                      debugPrint('Saved profile fave');

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e, st) {
                      debugPrint('ERROR saving profile fave: $e');
                      debugPrintStack(stackTrace: st);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to set profile favorite'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: posterPath.isEmpty
                        ? Container(
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white54,
                            ),
                          )
                        : Image.network(
                            TmdbConfig.imageBaseUrl + posterPath,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
