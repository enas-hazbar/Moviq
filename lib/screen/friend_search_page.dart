import 'dart:async';
import 'chats_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/moviq_scaffold.dart';
import '../widgets/nav_helpers.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'search_page.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final _queryController = TextEditingController();
  String _query = '';
  final Set<String> _friends = {};
  final Set<String> _sentRequests = {};
  final Set<String> _incomingRequests = {};
  StreamSubscription? _friendsSub;
  StreamSubscription? _sentSub;
  StreamSubscription? _incomingSub;

  String? _currentUsername;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _attachStreams();
    _loadCurrentUserInfo();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _friendsSub?.cancel();
    _sentSub?.cancel();
    _incomingSub?.cancel();
    super.dispose();
  }

  void _attachStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users').doc(user.uid);
    _friendsSub = users
        .collection('friends')
        .snapshots()
        .handleError((_) {})
        .listen((snapshot) {
      setState(() {
        _friends
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
      });
    });
    _sentSub = users
        .collection('sent_requests')
        .snapshots()
        .handleError((_) {})
        .listen((snapshot) {
      setState(() {
        _sentRequests
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
      });
    });
    _incomingSub = users
        .collection('friend_requests')
        .snapshots()
        .handleError((_) {})
        .listen((snapshot) {
      setState(() {
        _incomingRequests
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
      });
    });
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final email = user.email ?? '';
    final fallbackUsername =
        email.isNotEmpty && email.contains('@') ? email.split('@').first : null;
    String? username;
    String? photoUrl = user.photoURL;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      username = data?['username'] as String?;
      photoUrl = (data?['photoUrl'] as String?) ?? photoUrl;
    } catch (_) {
      // Ignore permission errors.
    }
    if (!mounted) return;
    setState(() {
      _currentUsername = (username != null && username.isNotEmpty) ? username : fallbackUsername;
      _currentPhotoUrl = photoUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Friends',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              onChanged: (value) => setState(() => _query = value.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by username',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFFE5A3A3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _RequestsSection(
                    onAccept: _acceptRequest,
                  ),
                  const SizedBox(height: 16),
                  _SearchResults(
                    query: _query,
                    friends: _friends,
                    sentRequests: _sentRequests,
                    incomingRequests: _incomingRequests,
                    onSendRequest: _sendRequest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest({
    required String targetUid,
    required String targetUsername,
    required String? targetPhotoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final requestData = {
      'uid': user.uid,
      'username': _currentUsername ?? 'User',
      'photoUrl': _currentPhotoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final sentData = {
      'uid': targetUid,
      'username': targetUsername,
      'photoUrl': targetPhotoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await users
        .doc(targetUid)
        .collection('friend_requests')
        .doc(user.uid)
        .set(requestData);
    await users.doc(user.uid).collection('sent_requests').doc(targetUid).set(sentData);
  }

  Future<void> _acceptRequest(String fromUid, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final users = FirebaseFirestore.instance.collection('users');
    final batch = FirebaseFirestore.instance.batch();
    final meRef = users.doc(user.uid);
    final fromRef = users.doc(fromUid);

    batch.set(
      meRef.collection('friends').doc(fromUid),
      {
        'uid': fromUid,
        'username': data['username'] ?? 'User',
        'photoUrl': data['photoUrl'] ?? '',
      },
    );
    batch.set(
      fromRef.collection('friends').doc(user.uid),
      {
        'uid': user.uid,
        'username': _currentUsername ?? 'User',
        'photoUrl': _currentPhotoUrl ?? '',
      },
    );
    batch.delete(meRef.collection('friend_requests').doc(fromUid));
    batch.delete(fromRef.collection('sent_requests').doc(user.uid));
    await batch.commit();
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

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({required this.onAccept});

  final Future<void> Function(String fromUid, Map<String, dynamic> data) onAccept;

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
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requests',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final doc in docs)
              _RequestRow(
                username: doc.data()['username'] as String? ?? 'User',
                photoUrl: doc.data()['photoUrl'] as String?,
                onAccept: () => onAccept(doc.id, doc.data()),
              ),
          ],
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.username,
    required this.photoUrl,
    required this.onAccept,
  });

  final String username;
  final String? photoUrl;
  final VoidCallback onAccept;

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
          Text(username, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          TextButton(
            onPressed: onAccept,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE5A3A3),
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
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.friends,
    required this.sentRequests,
    required this.incomingRequests,
    required this.onSendRequest,
  });

  final String query;
  final Set<String> friends;
  final Set<String> sentRequests;
  final Set<String> incomingRequests;
  final Future<void> Function({
    required String targetUid,
    required String targetUsername,
    required String? targetPhotoUrl,
  }) onSendRequest;

  @override
  Widget build(BuildContext context) {
    if (query.trim().length < 2) {
      return const Text(
        'Search for users to add.',
        style: TextStyle(color: Colors.white70),
      );
    }
    final end = '$query\uf8ff';
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: end)
        .limit(20)
        .snapshots()
        .handleError((_) {});

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text(
            'Search unavailable. Check Firestore rules.',
            style: TextStyle(color: Colors.white70),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('No users found.', style: TextStyle(color: Colors.white70));
        }
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        return Column(
          children: [
            for (final doc in docs)
              if (doc.id != currentUid)
                _UserRow(
                  uid: doc.id,
                  username: (doc.data()['username'] as String?) ?? 'User',
                  photoUrl: doc.data()['photoUrl'] as String?,
                  isFriend: friends.contains(doc.id),
                  isRequested: sentRequests.contains(doc.id),
                  isIncoming: incomingRequests.contains(doc.id),
                  onAdd: () => onSendRequest(
                    targetUid: doc.id,
                    targetUsername: (doc.data()['username'] as String?) ?? 'User',
                    targetPhotoUrl: doc.data()['photoUrl'] as String?,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.uid,
    required this.username,
    required this.photoUrl,
    required this.isFriend,
    required this.isRequested,
    required this.isIncoming,
    required this.onAdd,
  });

  final String uid;
  final String username;
  final String? photoUrl;
  final bool isFriend;
  final bool isRequested;
  final bool isIncoming;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    Widget action;
    if (isFriend) {
      action = const Text('Friends', style: TextStyle(color: Colors.white70));
    } else if (isRequested) {
      action = const Text('Requested', style: TextStyle(color: Colors.white70));
    } else if (isIncoming) {
      action = const Text('Request pending', style: TextStyle(color: Colors.white70));
    } else {
      action = TextButton(
        onPressed: onAdd,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFE5A3A3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Add', style: TextStyle(fontSize: 12)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Text(username, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          action,
        ],
      ),
    );
  }
}
