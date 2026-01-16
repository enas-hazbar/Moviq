import '../llm/moviq_prompt.dart';
import 'ollama_service.dart';
import 'chat_repository.dart';

class ChatManager {
  final _ollama = OllamaService();
  final _repo = ChatRepository();

  bool _isSending = false;

  Future<void> sendMessage({
    required String chatId,
    required String userMessage,
  }) async {
    if (_isSending) return;
    _isSending = true;

    await _repo.addMessage(chatId, 'user', userMessage);

    final prompt = '''
$moviqSystemPrompt

User: $userMessage
Assistant:
''';

    String buffer = '';

    await for (final token in _ollama.streamResponse(prompt)) {
      buffer += token;
    }

    await _repo.addMessage(chatId, 'assistant', buffer);

    _isSending = false;
  }
}
