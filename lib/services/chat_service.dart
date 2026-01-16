import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ollama_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OllamaService _ollama = OllamaService();

  /// CREATE OR GET AI CHAT
  Future<String> getOrCreateChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final query = await _firestore
        .collection('ai_chats')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final doc = await _firestore.collection('ai_chats').add({
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// STREAM MESSAGES
  Stream<QuerySnapshot<Map<String, dynamic>>> messageStream(String chatId) {
    return _firestore
        .collection('ai_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  /// USER MESSAGE
  Future<void> sendUserMessage(String chatId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('ai_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'role': 'user',
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// STREAM AI RESPONSE
  Stream<String> streamAssistantResponse(String userMessage) async* {
    final prompt = _buildSystemPrompt() +
        '\n\nUser: $userMessage\nAssistant:';

    yield* _ollama.streamResponse(prompt);
  }

  /// SAVE FINAL AI MESSAGE
  Future<void> saveAssistantMessage(
    String chatId,
    String content,
  ) async {
    await _firestore
        .collection('ai_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'role': 'assistant',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _buildSystemPrompt() {
    return '''
You are Moviq Assistant, a helpful movie recommendation and movie information chatbot.
Answer naturally and directly based on the user's message.
Keep answers concise and helpful.
''';
  }
}
