import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/tmdb_config.dart';
import 'movie_details_page.dart';
import 'add_movie_to_list_page.dart';
import 'share_list_page.dart';

class ListDetailsPage extends StatelessWidget {
  final String listId;
  final String listName;

  const ListDetailsPage({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(listName),
          actions: [
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareListPage(
              listType: 'custom',
              listId: listId,
              listName: listName,
            ),
          ),
        );
      },
    ),
  ],
      ),
      body: Stack(
        children: [
          // ✅ GRID (StreamBuilder)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('lists')
                .doc(listId)
                .collection('items')
                .orderBy('addedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'This list is empty',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final int movieId = (data['movieId'] as num).toInt();
                  final String posterPath = (data['posterPath'] ?? '').toString();

                  final posterUrl = posterPath.isEmpty
                      ? null
                      : '${TmdbConfig.imageBaseUrl}$posterPath';

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailsPage(movieId: movieId),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: posterUrl == null
                              ? Container(
                                  color: Colors.white12,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.movie_outlined,
                                    color: Colors.white38,
                                    size: 30,
                                  ),
                                )
                              : Image.network(posterUrl, fit: BoxFit.cover),
                        ),
                      ),

                      // ✅ REMOVE BUTTON
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('lists')
                                .doc(listId)
                                .collection('items')
                                .doc(movieId.toString())
                                .delete();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // ✅ CENTERED ADD BUTTON
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFE5A3A3),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMovieToListPage(
                        listId: listId,
                        listName: listName,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
