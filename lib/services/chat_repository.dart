import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> createChat() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .add({
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> addMessage(
    String chatId,
    String role,
    String content,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId);

    await chatRef.collection('messages').add({
      'role': role,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }
}
