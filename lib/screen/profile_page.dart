import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/moviq_scaffold.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'friend_search_page.dart';
import 'friend_profile_page.dart';
import '../widgets/nav_helpers.dart';
import '../config/tmdb_config.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _pink = Color(0xFFE5A3A3);
  static const TextStyle _sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

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
            Center(child: _ProfileAvatar()),
            const SizedBox(height: 28),

            // My Faves
            const _SectionHeader(title: 'My Faves:'),
            const SizedBox(height: 16),
            const SizedBox(height: 140),
            const SizedBox(height: 28),

            // Recent Activity
            const _SectionHeader(title: 'Recent Activity:'),
            const SizedBox(height: 16),
            _RecentActivityList(
              userId: FirebaseAuth.instance.currentUser?.uid,
            ),
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
        final data = snap.data?.data();
        final firestoreUrl = data?['photoUrl'] as String?;
        final photoUrl = (firestoreUrl != null && firestoreUrl.isNotEmpty)
            ? firestoreUrl
            : user.photoURL;

        if (photoUrl == null || photoUrl.isEmpty) {
          return const _AvatarShell(
            child: Icon(Icons.person, color: Colors.white, size: 48),
          );
        }

        return _AvatarShell(
          imageProvider: NetworkImage(photoUrl),
        );
      },
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final stream = FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80);
        }
        if (snapshot.hasError) {
          return const Text(
            'Unable to load recent activity.',
            style: TextStyle(color: Colors.white70),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No recent activity yet.',
            style: TextStyle(color: Colors.white70),
          );
        }
        return Column(
          children: [
            for (final doc in docs)
              _RecentReviewRow(data: doc.data() as Map<String, dynamic>),
          ],
        );
      },
    );
  }
}

class _RecentReviewRow extends StatelessWidget {
  const _RecentReviewRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String reviewText = (data['review'] as String?) ?? '';
    final int rating10 = (data['rating'] as num?)?.toInt() ?? 0;
    final int starRating = ((rating10 / 2).ceil()).clamp(0, 5);
    final String movieTitle = (data['movieTitle'] as String?) ?? 'Unknown movie';
    final String posterPath = (data['posterPath'] as String?) ?? '';

    final posterUrl =
        posterPath.isEmpty ? null : '${TmdbConfig.imageBaseUrl}$posterPath';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: posterUrl == null
                ? Container(
                    width: 60,
                    height: 84,
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: Colors.white38,
                      size: 22,
                    ),
                  )
                : Image.network(
                    posterUrl,
                    width: 60,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 84,
                      color: Colors.white12,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < starRating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFB37C78),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$rating10/10',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reviewText.trim().isEmpty ? 'Rating only' : reviewText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  movieTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
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
  const _AvatarShell({this.imageProvider, this.child});

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
