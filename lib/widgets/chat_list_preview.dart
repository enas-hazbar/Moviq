import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/tmdb_config.dart';

class ChatListBubblePreview extends StatelessWidget {
  final String ownerId;
  final String listType;
  final String? listId;
  final String listName;

  const ChatListBubblePreview({
    super.key,
    required this.ownerId,
    required this.listType,
    required this.listName,
    this.listId,
  });

  CollectionReference<Map<String, dynamic>> _itemsRef() {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(ownerId);

    if (listType == 'custom') {
      return userRef
          .collection('lists')
          .doc(listId)
          .collection('items');
    }

    return userRef.collection(listType); // watchlist, favorites, etc
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _itemsRef()
          .orderBy('addedAt', descending: true) // IMPORTANT
          .limit(4)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];

        final posters = docs
            .map((d) => d.data()['posterPath'] as String?)
            .where((p) => p != null && p!.isNotEmpty)
            .map((p) => '${TmdbConfig.imageBaseUrl}$p')
            .toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PosterCollage2x2(posters: posters),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    listName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PosterCollage2x2 extends StatelessWidget {
  final List<String> posters;
  const _PosterCollage2x2({required this.posters});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          children: [
            Row(
              children: [
                _tile(0),
                _tile(1),
              ],
            ),
            Row(
              children: [
                _tile(2),
                _tile(3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(int index) {
    if (index >= posters.length) {
      return Container(
        width: 32,
        height: 32,
        color: Colors.white24,
      );
    }

    return Image.network(
      posters[index],
      width: 32,
      height: 32,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 32,
        height: 32,
        color: Colors.white24,
      ),
    );
  }
}
