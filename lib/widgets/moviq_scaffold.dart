import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chats_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MoviqTopTab { films, reviews, friends, list }
enum MoviqBottomTab { dashboard, search, chat,chats, favorites, profile }

class MoviqScaffold extends StatelessWidget {
  const MoviqScaffold({
    super.key,
    required this.body,
    this.currentTopTab = MoviqTopTab.films,
    this.currentBottomTab = MoviqBottomTab.dashboard,
    this.onTopTabSelected,
    this.onBottomTabSelected,
    this.showTopNav = true,
  });

  final Widget body;
  final MoviqTopTab currentTopTab;
  final MoviqBottomTab currentBottomTab;
  final ValueChanged<MoviqTopTab>? onTopTabSelected;
  final ValueChanged<MoviqBottomTab>? onBottomTabSelected;
  final bool showTopNav;

  static const Color _background = Colors.black;
  static const Color _pink = Color(0xFFE5A3A3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MoviqHeader(),
            if (showTopNav)
              _TopNav(
                activeTab: currentTopTab,
                onSelected: onTopTabSelected,
              ),
            Expanded(child: body),
            _BottomNav(
              activeTab: currentBottomTab,
              onSelected: onBottomTabSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoviqHeader extends StatelessWidget {
  const _MoviqHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9E6E5), width: 2),
        ),
      ),
      child: const Center(
        child: Text(
          'M O V I Q',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: 7.5,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.activeTab,
    required this.onSelected,
  });

  final MoviqTopTab activeTab;
  final ValueChanged<MoviqTopTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (MoviqTopTab.films, 'Films'),
      (MoviqTopTab.reviews, 'Reviews'),
      (MoviqTopTab.friends, 'Friends'),
      (MoviqTopTab.list, 'List'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9E6E5), width: 2),
        ),
      ),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Expanded(
              child: InkWell(
                onTap: onSelected == null ? null : () => onSelected!(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: tab == activeTab ? MoviqScaffold._pink : Colors.transparent,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.activeTab,
    required this.onSelected,
  });

  final MoviqBottomTab activeTab;
  final ValueChanged<MoviqBottomTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    const entries = [
      (MoviqBottomTab.dashboard, 'assets/dashboard.png'),
      (MoviqBottomTab.search, 'assets/search.png'),
      (MoviqBottomTab.chat, 'assets/chatbot.png'),
      (MoviqBottomTab.chats, 'assets/chat.png'), 
      (MoviqBottomTab.favorites, 'assets/favorites.png'),
      (MoviqBottomTab.profile, 'assets/profile.png'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
          for (final (tab, asset) in entries)
            if (tab == MoviqBottomTab.chats)
              _ChatsBottomIcon(
                assetPath: asset,
                isActive: tab == activeTab,
                onTap: onSelected == null ? null : () => onSelected!(tab),
              )
            else
              _BottomIcon(
                assetPath: asset,
                isActive: tab == activeTab,
                onTap: onSelected == null ? null : () => onSelected!(tab),
              ),
          ],
        ),
      ),
    );
  }
}
class _ChatsBottomIcon extends StatelessWidget {
  const _ChatsBottomIcon({
    required this.assetPath,
    required this.isActive,
    this.onTap,
  });

  final String assetPath;
  final bool isActive;
  final VoidCallback? onTap;

  int _totalUnreadForMe(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String me) {
    final deduped = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in docs) {
      final data = d.data();
      final participants = (data['participants'] as List?)
              ?.whereType<String>()
              .toList() ??
          [];
      if (participants.isEmpty) continue;
      participants.sort();
      final key = participants.join('_');

      final existing = deduped[key];
      if (existing == null) {
        deduped[key] = d;
      } else {
        final existingData = existing.data();
        final existingAt = (existingData['lastMessageAt'] as Timestamp?) ??
            (existingData['updatedAt'] as Timestamp?);
        final currentAt =
            (data['lastMessageAt'] as Timestamp?) ??
                (data['updatedAt'] as Timestamp?);
        if ((currentAt?.millisecondsSinceEpoch ?? 0) >
            (existingAt?.millisecondsSinceEpoch ?? 0)) {
          deduped[key] = d;
        } else if (d.id == key) {
          deduped[key] = d;
        }
      }
    }

    var total = 0;
    final activeChatId = ChatsService.activeChatId.value;
    for (final entry in deduped.entries) {
      final key = entry.key;
      final d = entry.value;
      if (activeChatId != null && activeChatId == key) {
        continue;
      }
      final data = d.data();
      final lastMessageAt = data['lastMessageAt'] as Timestamp?;
      final lastSeenRaw = data['lastSeen'];
      final lastSeen =
          (lastSeenRaw is Map) ? lastSeenRaw[me] as Timestamp? : null;
      if (lastMessageAt != null &&
          lastSeen != null &&
          lastSeen.compareTo(lastMessageAt) >= 0) {
        continue;
      }

      final unreadRaw = data['unread'];
      var unreadCount = 0;
      if (unreadRaw is Map) {
        final unread = Map<String, dynamic>.from(unreadRaw);
        final val = unread[me];
        unreadCount = (val is num)
            ? val.toInt()
            : (val is String ? int.tryParse(val) ?? 0 : 0);
      } else if (unreadRaw is num) {
        unreadCount = unreadRaw.toInt();
      }

      if (unreadCount <= 0) {
        final lastSenderId = data['lastSenderId'];
        if (lastSenderId is String && lastSenderId != me) {
          unreadCount = 1;
        }
      }

      if (unreadCount > 0) {
        total += unreadCount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    // If not logged in, just show normal icon
    if (me == null) {
      return _BottomIcon(
        assetPath: assetPath,
        isActive: isActive,
        onTap: onTap,
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: ChatsService.activeChatId,
      builder: (context, _, __) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: me)
              .snapshots(),
          builder: (context, snap) {
            final totalUnread =
                snap.hasData ? _totalUnreadForMe(snap.data!.docs, me) : 0;
            final showBadge = totalUnread > 0;
            final badgeText = totalUnread > 99 ? '99+' : totalUnread.toString();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _BottomIcon(
                  assetPath: assetPath,
                  isActive: isActive,
                  onTap: onTap,
                ),

                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A3A3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}


class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.assetPath,
    required this.isActive,
    this.onTap,
  });

  final String assetPath;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = 32.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? MoviqScaffold._pink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          color: Colors.white,
        ),
      ),
    );
  }
}
