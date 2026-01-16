import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/moviq_scaffold.dart';
import '../widgets/nav_helpers.dart';
import '../services/chats_service.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'chat_room_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String _query = '';
  VoidCallback? _activeChatListener;
  bool _hasUnread(String chatId, Map<String, dynamic> data, String me) {
    final participants = (data['participants'] as List?)
            ?.whereType<String>()
            .toList() ??
        [];
    participants.sort();
    final key = participants.join('_');

    final activeChatId = ChatsService.activeChatId.value;
    if (activeChatId != null && activeChatId == key) {
      return false;
    }
    final lastMessageAt = data['lastMessageAt'] as Timestamp?;
    final lastSeenRaw = data['lastSeen'];
    final lastSeen = (lastSeenRaw is Map) ? lastSeenRaw[me] as Timestamp? : null;
    if (lastMessageAt != null &&
        lastSeen != null &&
        lastSeen.compareTo(lastMessageAt) >= 0) {
      return false;
    }

    final unreadRaw = data['unread'];
    if (unreadRaw is Map) {
      final val = unreadRaw[me];
      if (val is num && val.toInt() > 0) return true;
      if (val is String && int.tryParse(val) != null && int.parse(val) > 0) {
        return true;
      }
    } else if (unreadRaw is num && unreadRaw.toInt() > 0) {
      return true;
    }

    final lastSenderId = data['lastSenderId'];
    if (lastSenderId is String && lastSenderId != me) {
      if (lastMessageAt != null &&
          (lastSeen == null || lastSeen.compareTo(lastMessageAt) < 0)) {
        return true;
      }
    }
    return false;
  }
String timeAgo(Timestamp? ts) {
  if (ts == null) return '';

  final now = DateTime.now();
  final date = ts.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d';

  return '${date.day}/${date.month}/${date.year}';
}

@override
void initState() {
  super.initState();
  _fixOldChats();
  _activeChatListener = () {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  };
  ChatsService.activeChatId.addListener(_activeChatListener!);
}

@override
void dispose() {
  if (_activeChatListener != null) {
    ChatsService.activeChatId.removeListener(_activeChatListener!);
  }
  super.dispose();
}

Future<void> _fixOldChats() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final chats = await FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: uid)
      .get();

  for (final doc in chats.docs) {
    final data = doc.data();

    // Only fix chats that are missing lastMessageAt
    if (!data.containsKey('lastMessageAt') ||
        data['lastMessageAt'] == null) {
      await doc.reference.update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {

    final me = FirebaseAuth.instance.currentUser!.uid;
    final chatService = ChatsService();

    return MoviqScaffold(
      currentBottomTab: MoviqBottomTab.chats,
      showTopNav: false,
      onBottomTabSelected: (tab) => _handleBottomNav(context, tab),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatService.myChats(),
        builder: (context, chatSnap) {
          if (!chatSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          /// 🔹 Collect users that already have chats
          final activeChatUserIds = <String>{};
          final allChats = chatSnap.data!.docs;
          final filtered = allChats.where((doc) {
            if (_query.isEmpty) return true;

            final data = doc.data();
            final lastMsg =
                (data['lastMessage'] ?? '').toString().toLowerCase();

            return lastMsg.contains(_query);
          }).toList();

          final deduped = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
          for (final doc in filtered) {
            final data = doc.data();
            final participants = (data['participants'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                [];
            if (participants.isEmpty) continue;
            participants.sort();
            final key = participants.join('_');

            final existing = deduped[key];
            if (existing == null) {
              deduped[key] = doc;
            } else {
              final existingData = existing.data();
              final existingAt =
                  (existingData['lastMessageAt'] as Timestamp?) ??
                      (existingData['updatedAt'] as Timestamp?);
              final currentAt = (data['lastMessageAt'] as Timestamp?) ??
                  (data['updatedAt'] as Timestamp?);
              if ((currentAt?.millisecondsSinceEpoch ?? 0) >
                  (existingAt?.millisecondsSinceEpoch ?? 0)) {
                deduped[key] = doc;
              } else if (doc.id == key) {
                deduped[key] = doc;
              }
            }
          }

          final chats = deduped.values.toList();

          for (final doc in chats) {
            final participants = (doc['participants'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                [];
            final friendId =
                participants.firstWhere((id) => id != me, orElse: () => '');
            if (friendId.isEmpty) {
              continue;
            }
            activeChatUserIds.add(friendId);
          }

          return Column(
            children: [
              /// 🔍 Search (UI only for now)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search messages or friends',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              ),

              /// 📥 MESSAGES
              const _SectionTitle('Messages'),
            SizedBox(
            height: 260,
            child: chats.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (_, i) {
                      final data = chats[i].data();
                      final Timestamp? lastMessageAt =
                          data['lastMessageAt'] as Timestamp?;
                      final participants = (data['participants'] as List?)
                              ?.whereType<String>()
                              .toList() ??
                          [];
                      final friendId = participants.firstWhere(
                        (id) => id != me,
                        orElse: () => '',
                      );
                      if (friendId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final hasUnread = _hasUnread(chats[i].id, data, me);

                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friendId)
                            .snapshots(),
                        builder: (_, userSnap) {
                          final u = userSnap.data?.data();
                          if (u == null) return const SizedBox();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  (u['photoUrl'] ?? '').isNotEmpty
                                      ? NetworkImage(u['photoUrl'])
                                      : null,
                              child: (u['photoUrl'] ?? '').isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white70)
                                  : null,
                            ),
                            title: Text(
                              u['username'] ?? 'User',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              data['lastMessage'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(color: Colors.white54),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeAgo(lastMessageAt),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (hasUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE5A3A3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatRoomPage(friendId: friendId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),

              /// 👥 FRIENDS (ONLY friends without chats)
              const _SectionTitle('Friends'),
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(me)
                      .collection('friends')
                      .orderBy('username')
                      .snapshots(),
                  builder: (_, friendSnap) {
                    if (!friendSnap.hasData) {
                      return const SizedBox();
                    }

                  final friends = friendSnap.data!.docs
                      .where((f) {
                        if (activeChatUserIds.contains(f.id)) return false;

                        final username = (f.data()['username'] ?? 'User').toString().toLowerCase();
                        return _query.isEmpty || username.contains(_query);
                      })
                      .toList();

                    if (friends.isEmpty) {
                      return const Center(
                        child: Text(
                          'All friends already have chats',
                          style:
                              TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, i) {
                        final f = friends[i];
                        final data = f.data();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (data['photoUrl'] ?? '').isNotEmpty
                                    ? NetworkImage(data['photoUrl'])
                                    : null,
                            child: (data['photoUrl'] ?? '').isEmpty
                                ? const Icon(Icons.person,
                                    color: Colors.white70)
                                : null,
                          ),
                          title: Text(
                            data['username'] ?? 'User',
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                          trailing: const Icon(Icons.chat,
                              color: Colors.white70),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                    friendId: f.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleBottomNav(BuildContext context, MoviqBottomTab tab) {
    navigateWithSlide(
      context: context,
      current: MoviqBottomTab.chats,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
