import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
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
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- TEXT ----------------
  Future<void> sendText(String otherUid, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await ensureChatExists(otherUid);

    await _messagesRef(otherUid).add({
      'type': 'text',
      'senderId': uid,
      'text': t,
      'imageUrl': null,
      'storagePath': null,
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [uid],
      'deleted': false,
      'reactions': {}, // keeps type stable
    });

    await _chatRef(otherUid).set({
      'lastMessage': t,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- IMAGE ----------------
  Future<void> sendImage(String otherUid, File file) async {
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
      'storagePath': path,
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [uid],
      'deleted': false,
      'reactions': {},
    });

    await _chatRef(otherUid).set({
      'lastMessage': '📷 Photo',
      'lastMessageType': 'image',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ---------------- STREAMS ----------------
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String otherUid) {
    return _messagesRef(otherUid).orderBy('createdAt').snapshots();
  }

  // ---------------- SEEN ----------------
  Future<void> markSeen(String otherUid) async {
    await _chatRef(otherUid).set({
      'unread.$uid': 0,
    }, SetOptions(merge: true));
  }

  // ---------------- TYPING ----------------
  Future<void> setTyping(String otherUid, bool typing) async {
    await ensureChatExists(otherUid);
    await _chatRef(otherUid).set({
      'typing.$uid': typing,
    }, SetOptions(merge: true));
  }

  Stream<bool> typingStream(String otherUid) {
    return _chatRef(otherUid).snapshots().map(
          (s) => (s.data()?['typing'] as Map?)?[otherUid] == true,
        );
  }

  // ---------------- EDIT ----------------
  Future<void> editMessage(String otherUid, String messageId, String newText) async {
    await _messagesRef(otherUid).doc(messageId).update({
      'text': newText.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });

    await _chatRef(otherUid).set({
      'lastMessage': newText.trim(),
    }, SetOptions(merge: true));
  }

  // ---------------- DELETE ----------------
  Future<void> deleteMessage(String otherUid, String messageId) async {
    final ref = _messagesRef(otherUid).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    final storagePath = data['storagePath'];

    // delete file if it's an image and path exists
    if (storagePath is String && storagePath.isNotEmpty) {
      await _storage.ref(storagePath).delete();
    }

    // soft-delete message
    await ref.update({
      'deleted': true,
      'text': null,
      'imageUrl': null,
      'storagePath': null,
    });
  }

  // ---------------- REACTIONS ----------------
  Future<void> reactToMessage({
    required String otherUid,
    required String messageId,
    required String emoji,
  }) async {
    final ref = _messagesRef(otherUid).doc(messageId);

    if (emoji.isEmpty) {
      await ref.update({'reactions.$uid': FieldValue.delete()});
    } else {
      await ref.set({'reactions.$uid': emoji}, SetOptions(merge: true));
    }
  }

  Future<void> toggleHeart({
    required String otherUid,
    required String messageId,
  }) async {
    final ref = _messagesRef(otherUid).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    final raw = data['reactions'];

    final Map<String, dynamic> reactions =
        (raw is Map) ? Map<String, dynamic>.from(raw) : {};

    final current = reactions[uid]?.toString();

    if (current == '❤️') {
      await ref.update({'reactions.$uid': FieldValue.delete()});
    } else {
      await ref.set({'reactions.$uid': '❤️'}, SetOptions(merge: true));
    }
  }
    Stream<QuerySnapshot<Map<String, dynamic>>> myChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
Future<void> sendVoiceMessage(String otherUid, File file) async {
  await ensureChatExists(otherUid);

  final msgDoc = _messagesRef(otherUid).doc();
  final path = 'voice_messages/${chatIdWith(otherUid)}/${msgDoc.id}.m4a';

  await _storage.ref(path).putFile(file);
  final url = await _storage.ref(path).getDownloadURL();

  await msgDoc.set({
    'type': 'voice',
    'senderId': uid,
    'voiceUrl': url, // 👈 REQUIRED
    'storagePath': path,
    'createdAt': FieldValue.serverTimestamp(),
    'seenBy': [uid],
  });
}
Future<void> sendList({
  required String otherUid,
  required String listType, // 'custom' | 'watchlist' | 'watched'
  String? listId,           // only for custom
  required String listName,
}) async {
  await ensureChatExists(otherUid);

  await _messagesRef(otherUid).add({
    'type': 'list',
    'senderId': uid,

    // 🔑 list reference
    'listType': listType,
    'listId': listId,
    'listOwnerId': uid,
    'listName': listName,

    'createdAt': FieldValue.serverTimestamp(),
    'seenBy': [uid],
  });

  await _chatRef(otherUid).set({
    'lastMessage': '📋 Shared: $listName',
    'lastMessageType': 'list',
    'lastMessageAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'unread.$otherUid': FieldValue.increment(1),
  }, SetOptions(merge: true));
}

}
