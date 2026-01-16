class ChatMemoryService {
  ChatMemoryService._();
  static final ChatMemoryService instance = ChatMemoryService._();

  final List<ChatMessage> messages = [];
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}
