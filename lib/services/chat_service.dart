import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://moviq-1cbf7.firebasestorage.app',
  );

  String get uid => _auth.currentUser!.uid;

  String chatIdWith(String otherUid) {
    final ids = [uid, otherUid]..sort();
    return ids.join('_');
  }

  DocumentReference<Map<String, dynamic>> _chatRef(String otherUid) {
    return _db.collection('chats').doc(chatIdWith(otherUid));
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String otherUid) {
    return _chatRef(otherUid).collection('messages');
  }

  Future<void> ensureChatExists(String otherUid) async {
    final ref = _chatRef(otherUid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'participants': [uid, otherUid],
      'typing': {uid: false, otherUid: false},
      'unread': {uid: 0, otherUid: 0},
      'lastMessage': '',
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': {},
    });
  }

  // ---------------- STREAMS ----------------
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String otherUid) {
    return _messagesRef(otherUid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  // ---------------- SEEN / UNREAD ----------------
  Future<void> markSeen(String otherUid) async {
    // Reset unread counter for me
    await _chatRef(otherUid).set({
      'unread.$uid': 0,
      'lastSeen.$uid': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add me into seenBy for recent messages (simple + safe)
    final recent = await _messagesRef(otherUid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final batch = _db.batch();
    for (final doc in recent.docs) {
      final data = doc.data();
      if (data['deleted'] == true) continue;

      final seenByRaw = data['seenBy'];
      final List<dynamic> seenBy = (seenByRaw is List) ? seenByRaw : [];
      if (!seenBy.contains(uid)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  // ---------------- TYPING ----------------
  Future<void> setTyping(String otherUid, bool typing) async {
    await ensureChatExists(otherUid);
    await _chatRef(otherUid).set({
      'typing.$uid': typing,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<bool> typingStream(String otherUid) {
    return _chatRef(otherUid).snapshots().map((s) {
      final data = s.data();
      final typing = data?['typing'];
      if (typing is Map) return typing[otherUid] == true;
      return false;
    });
  }

  // ---------------- SEND: TEXT ----------------
  Future<void> sendText(
    String otherUid,
    String text, {
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await ensureChatExists(otherUid);

    await _messagesRef(otherUid).add({
      'type': 'text',
      'senderId': uid,
      'text': t,
      'imageUrl': null,
      'voiceUrl': null,
      'storagePath': null,

      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'editedAt': null,

      'seenBy': [uid],
      'deleted': false,

      // { "<uid>": "❤️" } etc.
      'reactions': <String, dynamic>{},
    });

    await _chatRef(otherUid).set({
      'lastMessage': t,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- SEND: IMAGE ----------------
  Future<void> sendImage(
    String otherUid,
    File file, {
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    await ensureChatExists(otherUid);

    final msgDoc = _messagesRef(otherUid).doc();
    final path = 'chat_images/${chatIdWith(otherUid)}/${msgDoc.id}.jpg';

    await _storage.ref(path).putFile(file);
    final url = await _storage.ref(path).getDownloadURL();

    await msgDoc.set({
      'type': 'image',
      'senderId': uid,
      'text': null,
      'imageUrl': url,
      'voiceUrl': null,
      'storagePath': path,

      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'editedAt': null,

      'seenBy': [uid],
      'deleted': false,
      'reactions': <String, dynamic>{},
    });

    await _chatRef(otherUid).set({
      'lastMessage': '📷 Photo',
      'lastMessageType': 'image',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- SEND: VOICE ----------------
  Future<void> sendVoiceMessage(
    String otherUid,
    File file, {
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    await ensureChatExists(otherUid);

    final msgDoc = _messagesRef(otherUid).doc();
    final path = 'voice_messages/${chatIdWith(otherUid)}/${msgDoc.id}.m4a';

    await _storage.ref(path).putFile(file);
    final url = await _storage.ref(path).getDownloadURL();

    await msgDoc.set({
      'type': 'voice',
      'senderId': uid,
      'text': null,
      'imageUrl': null,
      'voiceUrl': url,
      'storagePath': path,

      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'editedAt': null,

      'seenBy': [uid],
      'deleted': false,
      'reactions': <String, dynamic>{},
    });

    await _chatRef(otherUid).set({
      'lastMessage': '🎤 Voice message',
      'lastMessageType': 'voice',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- SEND: LIST (custom / watchlist / watched) ----------------
  Future<void> sendList({
    required String otherUid,
    required String listType, // 'custom' | 'watchlist' | 'watched'
    String? listId, // only for custom
    required String listName,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    await ensureChatExists(otherUid);

    await _messagesRef(otherUid).add({
      'type': 'list',
      'senderId': uid,
      'text': null,
      'imageUrl': null,
      'voiceUrl': null,
      'storagePath': null,

      'listType': listType,
      'listId': listId,
      'listOwnerId': uid,
      'listName': listName,

      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'editedAt': null,

      'seenBy': [uid],
      'deleted': false,
      'reactions': <String, dynamic>{},
    });

    await _chatRef(otherUid).set({
      'lastMessage': '📋 Shared: $listName',
      'lastMessageType': 'list',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- EDIT ----------------
  Future<void> editMessage({
    required String otherUid,
    required String messageId,
    required String newText,
  }) async {
    final t = newText.trim();
    if (t.isEmpty) return;

    final ref = _messagesRef(otherUid).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    if ((data['senderId'] ?? '').toString() != uid) return;
    if ((data['type'] ?? '').toString() != 'text') return;
    if (data['deleted'] == true) return;

    await ref.update({
      'text': t,
      'editedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(otherUid).set({
      'lastMessage': t,
      'lastMessageType': 'text',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- DELETE (soft delete + delete stored file) ----------------
  Future<void> deleteMessage({
    required String otherUid,
    required String messageId,
  }) async {
    final ref = _messagesRef(otherUid).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    if ((data['senderId'] ?? '').toString() != uid) return;

    final storagePath = data['storagePath'];
    if (storagePath is String && storagePath.isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {}
    }

    await ref.update({
      'deleted': true,
      'text': null,
      'imageUrl': null,
      'voiceUrl': null,
      'storagePath': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

Future<void> reactToMessage({
  required String otherUid,
  required String messageId,
  required String emoji, // '' to remove
}) async {
  final ref = _messagesRef(otherUid).doc(messageId);

  if (emoji.isEmpty) {
    await ref.update({
      'reactions.$uid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return;
  }

  await ref.update({
    'reactions.$uid': emoji,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


Future<void> toggleHeart({
  required String otherUid,
  required String messageId,
}) async {
  final ref = _messagesRef(otherUid).doc(messageId);
  final snap = await ref.get();
  if (!snap.exists) return;

  final data = snap.data() ?? {};
  final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
  final current = reactions[uid];

  if (current == '❤️') {
    await ref.update({
      'reactions.$uid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } else {
    await ref.update({
      'reactions.$uid': '❤️',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

}
