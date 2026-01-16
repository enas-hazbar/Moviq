import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ollama_service.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final OllamaService _ollama = OllamaService();

  Future<String> getOrCreateChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final doc = await _firestore.collection('chats').add({
      'participants': [user.uid, 'assistant'],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    return doc.id;
  }

  Stream<QuerySnapshot> messageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendUserMessage(String chatId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'role': 'user',
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
    });
  }

  Stream<String> streamAssistantResponse(String userMessage) async* {
    final systemPrompt = _buildSystemPrompt();
    final fullPrompt = '$systemPrompt\n\nUser: $userMessage\nAssistant:';

    yield* _ollama.streamResponse(fullPrompt);
  }

  Future<void> saveAssistantMessage(
    String chatId,
    String content,
  ) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': 'assistant',
      'role': 'assistant',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
    });
  }

  String _buildSystemPrompt() {
    return '''
You are Moviq Assistant, a helpful movie recommendation and movie information chatbot.
Answer naturally and directly based on the user's message.
Do not repeat the same generic recommendation every time.
If the user asks for recommendations, ask one short follow-up question only if needed.
Keep answers concise and helpful.
''';
  }
}
