import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/moviq_scaffold.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'friend_search_page.dart';
import 'friend_profile_page.dart';
import '../config/tmdb_config.dart';
import '../widgets/nav_helpers.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/recently_viewed_list.dart';
import 'PickFavoriteForSlotPage.dart';
// import 'chat_room_page.dart';
import 'chats_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const Color _pink = Color(0xFFE5A3A3);
  static const TextStyle _sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingCover = false;

  Future<void> _pickAndUploadCover() async {
    if (_isUploadingCover) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final file = File(picked.path);
      final fileName = DateTime.now().millisecondsSinceEpoch;
      final path = 'profile_photos/${user.uid}/cover_$fileName.jpg';
      final url = await _uploadWithFallback(path, file);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'coverPhotoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload cover: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<String> _uploadWithFallback(String path, File file) async {
    try {
      return await _uploadToBucket(FirebaseStorage.instance, path, file);
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found' && e.code != 'bucket-not-found') {
        rethrow;
      }
      final fallbackStorage = FirebaseStorage.instanceFor(
        bucket: 'gs://moviq-1cbf7.firebasestorage.app',
      );
      return await _uploadToBucket(fallbackStorage, path, file);
    }
  }

  Future<String> _uploadToBucket(
    FirebaseStorage storage,
    String path,
    File file,
  ) async {
    final ref = storage.ref(path);
    final snapshot = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      slideRoute(page: const SettingsPage(), fromRight: true),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProfileHeader(
              onCoverTap: _pickAndUploadCover,
              isUploading: _isUploadingCover,
            ),
            const SizedBox(height: 42),

            // My Faves
            const _SectionHeader(title: 'My Faves:'),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('profile_faves')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  // Placeholder while loading
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _AddPosterPlaceholder(slotId: 'slot_1'),
                      _AddPosterPlaceholder(slotId: 'slot_2'),
                      _AddPosterPlaceholder(slotId: 'slot_3'),
                    ],
                  );
                }

                final docs = snapshot.data!.docs;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    final slotId = 'slot_${index + 1}';

                    // Null-safe document lookup
                    final doc = docs.where((d) => d.id == slotId).isNotEmpty
                        ? docs.firstWhere((d) => d.id == slotId)
                        : null;

                    final posterPath = doc?.get('posterPath') as String? ?? '';

                    return GestureDetector(
                      onTap: () async {
                        final selectedMovie = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PickFavoriteForSlotPage(slotId: slotId),
                          ),
                        );

                        if (selectedMovie != null) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('profile_faves')
                                .doc(slotId)
                                .set({
                              'movieId': selectedMovie['movieId'],
                              'posterPath': selectedMovie['posterPath'],
                              'addedAt': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved profile fave'),
                                backgroundColor: ProfilePage._pink,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                          image: posterPath.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    '${TmdbConfig.imageBaseUrl}$posterPath',
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: posterPath.isEmpty
                            ? const Center(
                                child: Icon(Icons.add, color: Colors.white70, size: 40),
                              )
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),



            // Recent Activity
            const _SectionHeader(title: 'Recent Activity:'),
            const SizedBox(height: 16),
            RecentActivityList(userId: FirebaseAuth.instance.currentUser?.uid),
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Recently Viewed:'),
            const SizedBox(height: 12),
            RecentlyViewedList(userId: FirebaseAuth.instance.currentUser?.uid),
            const SizedBox(height: 28),

            // Friend List
            Row(
              children: [
                const _SectionHeader(title: 'Friend List:'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      slideRoute(page: const FriendSearchPage(), fromRight: true),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FriendRequestsPanel(),
            const SizedBox(height: 12),
            const _FriendList(),
          ],
        ),
      ),
    );
  }

  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    navigateWithSlide(
      context: context,
      current: MoviqBottomTab.profile,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: ProfilePage._sectionTitle);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onCoverTap,
    required this.isUploading,
  });

  final VoidCallback onCoverTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ProfileCover(
            onTap: onCoverTap,
            isUploading: isUploading,
          ),
          Positioned(
            left: 16,
            bottom: -18,
            child: _ProfileAvatar(),
          ),
        ],
      ),
    );
  }
}

class _ProfileCover extends StatelessWidget {
  const _ProfileCover({
    required this.onTap,
    required this.isUploading,
  });

  final VoidCallback onTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _coverPlaceholder();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return _coverPlaceholder();
        }
        final data = snap.data!.data();
        final coverUrl = data?['coverPhotoUrl'] as String?;
        final hasUrl = coverUrl != null && coverUrl.isNotEmpty;

        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasUrl)
                    Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                  else
                    _coverPlaceholder(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0E0E0E)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white38, size: 28),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _AvatarShell(
        child: Icon(Icons.person, color: Colors.white, size: 48),
      );
    }

return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots(),
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const _AvatarShell(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!snap.hasData || !snap.data!.exists) {
      return const _AvatarShell(
        child: Icon(Icons.person, color: Colors.white, size: 48),
      );
    }

    final data = snap.data!.data();
    final photoUrl = data?['photoUrl'] as String?;
    final safeUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;

    if (safeUrl == null) {
      return const _AvatarShell(
        child: Icon(Icons.person, color: Colors.white, size: 48),
      );
    }

return _AvatarShell(
  key: ValueKey(safeUrl),
  imageProvider: NetworkImage(safeUrl),
);

  },
);
  }
}

class _FriendList extends StatelessWidget {
  const _FriendList();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final friendsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .orderBy('username')
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: friendsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 24);
        }
        if (snapshot.hasError) {
          return const Text(
            'Unable to load friends.',
            style: TextStyle(color: Colors.white70),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            for (final doc in docs)
              _FriendRow(
                friendId: doc.id,
                username: (doc.data()['username'] as String?) ?? 'User',
                photoUrl: doc.data()['photoUrl'] as String?,
              ),
          ],
        );
      },
    );
  }
}

class _FriendRequestsPanel extends StatefulWidget {
  const _FriendRequestsPanel();

  @override
  State<_FriendRequestsPanel> createState() => _FriendRequestsPanelState();
}

class _FriendRequestsPanelState extends State<_FriendRequestsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friend_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;
        return Column(
          children: [
            InkWell(
              onTap: count == 0 ? null : () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Text(
                    'Requests',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  _RequestCount(count: count),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            if (_expanded && count > 0) ...[
              const SizedBox(height: 10),
              for (final doc in docs)
                _RequestActionRow(
                  requesterId: doc.id,
                  username: (doc.data()['username'] as String?) ?? 'User',
                  photoUrl: doc.data()['photoUrl'] as String?,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _RequestCount extends StatelessWidget {
  const _RequestCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ProfilePage._pink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RequestActionRow extends StatelessWidget {
  const _RequestActionRow({
    required this.requesterId,
    required this.username,
    required this.photoUrl,
  });

  final String requesterId;
  final String username;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black,
              backgroundImage:
                  (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _ignoreRequest(context, requesterId),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ignore', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _acceptRequest(context, requesterId, username, photoUrl),
            style: TextButton.styleFrom(
              backgroundColor: ProfilePage._pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    String fromUid,
    String fromUsername,
    String? fromPhoto,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final meRef = users.doc(user.uid);
    final fromRef = users.doc(fromUid);

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      meRef.collection('friends').doc(fromUid),
      {
        'uid': fromUid,
        'username': fromUsername,
        'photoUrl': fromPhoto ?? '',
      },
    );
    batch.set(
      fromRef.collection('friends').doc(user.uid),
      {
        'uid': user.uid,
        'username': _currentUsername(context) ?? 'User',
        'photoUrl': _currentPhotoUrl(context) ?? '',
      },
    );
    batch.delete(meRef.collection('friend_requests').doc(fromUid));
    batch.delete(fromRef.collection('sent_requests').doc(user.uid));
    await batch.commit();
  }

  Future<void> _ignoreRequest(BuildContext context, String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(users.doc(user.uid).collection('friend_requests').doc(fromUid));
    batch.delete(users.doc(fromUid).collection('sent_requests').doc(user.uid));
    await batch.commit();
  }

  String? _currentUsername(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }
    return null;
  }

  String? _currentPhotoUrl(BuildContext context) {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friendId,
    required this.username,
    required this.photoUrl,
  });

  final String friendId;
  final String username;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                slideRoute(
                  page: FriendProfilePage(
                    userId: friendId,
                    username: username,
                    photoUrl: photoUrl,
                  ),
                  fromRight: true,
                ),
              );
            },
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black,
                backgroundImage:
                    (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            username,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const Spacer(),
        //   IconButton(
        //   icon: const Icon(Icons.chat, color: Colors.white),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => ChatRoomPage(friendId: friendId),
        //       ),
        //     );
        //   },
        // ),
          const SizedBox(width: 6),
         _RemoveFriendButton(friendId: friendId),
        ],
      ),
    );
  }
}

class _RemoveFriendButton extends StatelessWidget {
  const _RemoveFriendButton({required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final batch = FirebaseFirestore.instance.batch();
        final meRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .doc(friendId);
        final themRef = FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('friends')
            .doc(user.uid);
        batch.delete(meRef);
        batch.delete(themRef);
        await batch.commit();
      },
      style: TextButton.styleFrom(
        backgroundColor: ProfilePage._pink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Remove', style: TextStyle(fontSize: 12)),
    );
  }
}

class _AvatarShell extends StatelessWidget {
  const _AvatarShell({
    super.key,
    this.imageProvider,
    this.child,
  });

  final ImageProvider? imageProvider;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.black,
        backgroundImage: imageProvider,
        child: child,
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.movie, color: Colors.white54, size: 36),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _AddPosterPlaceholder extends StatelessWidget {
  final String slotId;

  const _AddPosterPlaceholder({required this.slotId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PickFavoriteForSlotPage(slotId: slotId),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white70, size: 40),
        ),
      ),
    );
  }
}



class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.placeholders});

  final List<_PosterPlaceholder> placeholders;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final poster in placeholders) ...[
          poster,
          const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.title,
    required this.subtitle,
    this.poster,
  });

  final String title;
  final String subtitle;
  final Widget? poster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poster ??
              Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported, color: Colors.white54),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
