import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../services/chat_service.dart';
import 'shared_list_details_page.dart';
import 'shared_spical_page.dart';
import '../widgets/chat_list_preview.dart';

class ChatRoomPage extends StatefulWidget {
  final String friendId;
  const ChatRoomPage({super.key, required this.friendId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  DateTime? _lastTapTime;
static const _doubleTapDelay = Duration(milliseconds: 300);
  final _chat = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // reply state
  String? _replyToMessageId;
  String? _replyToText;
  String? _replyToSender;

  // voice record state
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasVoicePreview = false;
  String? _recordPath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  late final VoicePlaybackController _voiceController;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  bool _markingSeen = false;

  late final String me;
  late final String other;

  String _otherName = 'Friend';

  @override
  void initState() {
    super.initState();
    me = FirebaseAuth.instance.currentUser!.uid;
    other = widget.friendId;

    _voiceController = VoicePlaybackController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _chat.setActiveChat(other);
      await _chat.markSeen(other);
    });

    _messagesSub = _chat.messagesStream(other).listen((snap) async {
      if (_markingSeen || snap.docs.isEmpty) return;
      final last = snap.docs.last.data();
      if ((last['senderId'] ?? '') == me) return;
      _markingSeen = true;
      try {
        await _chat.markSeen(other);
      } finally {
        _markingSeen = false;
      }
    });

    _chatSub = _chat.chatStream(other).listen((snap) async {
      final data = snap.data();
      if (data == null || _markingSeen) return;
      final lastSenderId = data['lastSenderId'];
      if (lastSenderId is String && lastSenderId != me) {
        final lastMessageAt = data['lastMessageAt'] as Timestamp?;
        final lastSeenRaw = data['lastSeen'];
        final lastSeen = (lastSeenRaw is Map) ? lastSeenRaw[me] as Timestamp? : null;
        if (lastMessageAt != null &&
            (lastSeen == null || lastSeen.compareTo(lastMessageAt) < 0)) {
          _markingSeen = true;
          try {
            await _chat.markSeen(other);
          } finally {
            _markingSeen = false;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _chat.setActiveChat(null);
    _messagesSub?.cancel();
    _chatSub?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  // ------------------- helpers -------------------

  Color _bubbleColor(bool isMe) =>
      isMe ? const Color(0xFFE5A3A3) : Colors.white12;

  Widget _bubbleWrap({required bool isMe, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: _bubbleColor(isMe),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  // ------------------- reactions & actions -------------------

  void _toggleHeart(String messageId) {
    _chat.toggleHeart(otherUid: other, messageId: messageId);
  }

  void _openActionsFromBox({
    required RenderBox box,
    required String messageId,
    required bool isMeMsg,
    required String type,
    required String text,
  }) {
    final rect = box.localToGlobal(Offset.zero) & box.size;

    _showMessageActions(
      bubbleRect: rect,
      messageId: messageId,
      isMeMsg: isMeMsg,
      deleted: false,
      type: type,
      text: text,
    );
  }

Widget _bubbleGesture({
  required Widget child,
  required VoidCallback? onLongPress,
  required VoidCallback? onDoubleTap,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    child: child,
  );
}



Widget _messageWrapper({
  required BuildContext bubbleContext,
  required bool isMeMsg,
  required String messageId,
  required String type,
  required String textForActions,
  required Widget child,
}) {
  return _bubbleGesture(
    onLongPress: () {
      final box = bubbleContext.findRenderObject() as RenderBox;
      _openActionsFromBox(
        box: box,
        messageId: messageId,
        isMeMsg: isMeMsg,
        type: type,
        text: textForActions,
      );
    },
    onDoubleTap: () => _toggleHeart(messageId),
    child: child,
  );
}


  Future<void> _showEditDialog({
    required String messageId,
    required String initialText,
  }) async {
    final c = TextEditingController(text: initialText);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Edit message',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
          autofocus: true,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, c.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res == null) return;
    final t = res.trim();
    if (t.isEmpty) return;

    await _chat.editMessage(otherUid: other, messageId: messageId, newText: t);
  }

  void _showMessageActions({
    required Rect bubbleRect,
    required String messageId,
    required bool isMeMsg,
    required bool deleted,
    required String type,
    required String text,
  }) {
    if (deleted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Stack(
              children: [
                Positioned(
                  top: bubbleRect.top - 56,
                  left: isMeMsg ? null : bubbleRect.left,
                  right: isMeMsg
                      ? (MediaQuery.of(context).size.width - bubbleRect.right)
                      : null,
                  child: _ReactionPill(
                    onSelect: (emoji) async {
                      await _chat.reactToMessage(
                        otherUid: other,
                        messageId: messageId,
                        emoji: emoji,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Colors.white12)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.reply, color: Colors.white),
                            title: const Text('Reply', style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context);

                              final String replyPreviewText = text.trim().isNotEmpty
                                  ? text
                                  : (type == 'image')
                                      ? '📷 Photo'
                                      : (type == 'voice')
                                          ? '🎤 Voice message'
                                          : '📋 Shared list';

                              setState(() {
                                _replyToMessageId = messageId;
                                _replyToText = replyPreviewText;
                                _replyToSender = isMeMsg ? 'You' : _otherName;
                              });

                              _focusNode.requestFocus();
                            },
                          ),
                          if (isMeMsg && type == 'text')
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.white),
                              title: const Text('Edit', style: TextStyle(color: Colors.white)),
                              onTap: () async {
                                Navigator.pop(context);
                                await _showEditDialog(
                                  messageId: messageId,
                                  initialText: text,
                                );
                              },
                            ),
                          if (isMeMsg)
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.redAccent),
                              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              onTap: () async {
                                Navigator.pop(context);
                                await _chat.deleteMessage(otherUid: other, messageId: messageId);
                              },
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------- voice recording -------------------

  Future<void> _startRecording() async {
    final ok = await _recorder.hasPermission();
    if (!ok) return;

    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );

    _recordDuration = Duration.zero;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });

    setState(() {
      _isRecording = true;
      _hasVoicePreview = false;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _recordTimer?.cancel();

    setState(() {
      _isRecording = false;
      _hasVoicePreview = true;
    });
  }

  void _deleteVoicePreview() {
    try {
      final p = _recordPath;
      if (p != null) File(p).deleteSync();
    } catch (_) {}

    setState(() {
      _hasVoicePreview = false;
      _recordPath = null;
      _recordDuration = Duration.zero;
    });
  }

  Future<void> _sendVoice() async {
    if (_recordPath == null) return;

    await _chat.sendVoiceMessage(
      other,
      File(_recordPath!),
      replyToId: _replyToMessageId,
      replyToText: _replyToText,
      replyToSender: _replyToSender,
    );

    _clearReply();
    _deleteVoicePreview();
  }

  // ------------------- send text/image -------------------

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToText = null;
      _replyToSender = null;
    });
  }

  Future<void> _sendText() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    await _chat.sendText(
      other,
      txt,
      replyToId: _replyToMessageId,
      replyToText: _replyToText,
      replyToSender: _replyToSender,
    );

    _controller.clear();
    _clearReply();
  }

  Future<void> _sendPickedImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;

    await _chat.sendImage(
      other,
      File(picked.path),
      replyToId: _replyToMessageId,
      replyToText: _replyToText,
      replyToSender: _replyToSender,
    );

    _clearReply();
  }

  // ------------------- message builder -------------------

  Widget _buildMessage({
    required BuildContext bubbleContext,
    required String type,
    required String text,
    required String imageUrl,
    required String voiceUrl,
    required bool deleted,
    required bool isMeMsg,
    required String messageId,
    required String? replyToText,
    required String? replyToSender,
    required Map<String, dynamic> m,
  }) {
    if (deleted) {
      return _bubbleWrap(
        isMe: isMeMsg,
        child: const Text(
          'This message was deleted',
          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
        ),
      );
    }

    final bool hasReply = (replyToText != null && replyToText.trim().isNotEmpty);

    Widget replyPreview() {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isMeMsg ? Colors.white : const Color(0xFFE5A3A3),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (replyToSender == null || replyToSender.isEmpty) ? 'Reply' : replyToSender,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              replyToText ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // TEXT ✅
if (type == 'text') {
  return _messageWrapper(
    bubbleContext: bubbleContext,
    isMeMsg: isMeMsg,
    messageId: messageId,
    type: type,
    textForActions: text,
    child: Material(
      color: Colors.transparent,
      child: _bubbleWrap(
        isMe: isMeMsg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasReply) replyPreview(),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  );
}

    // IMAGE ✅
    if (type == 'image') {
      return _messageWrapper(
        bubbleContext: bubbleContext,
        isMeMsg: isMeMsg,
        messageId: messageId,
        type: type,
        textForActions: '📷 Photo',
        child: _bubbleWrap(
          isMe: isMeMsg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasReply) replyPreview(),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 240, fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      );
    }

    // VOICE ✅
    if (type == 'voice') {
      return _messageWrapper(
        bubbleContext: bubbleContext,
        isMeMsg: isMeMsg,
        messageId: messageId,
        type: type,
        textForActions: '🎤 Voice message',
        child: _bubbleWrap(
          isMe: isMeMsg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasReply) replyPreview(),
              VoiceMessageBubble(
                messageId: messageId,
                url: voiceUrl,
                controller: _voiceController,
                bubbleColor: Colors.transparent,
              ),
            ],
          ),
        ),
      );
    }

    // LIST ✅ FINAL FIX
if (type == 'list') {
  final String? listType = m['listType'] as String?;
  final String? ownerId = m['listOwnerId'] as String?;
  final String? listId = m['listId'] as String?;
  final String listName = (m['listName'] ?? 'Shared list').toString();

  return _messageWrapper(
    bubbleContext: bubbleContext,
    isMeMsg: isMeMsg,
    messageId: messageId,
    type: type,
    textForActions: listName,
    child: _bubbleWrap(
      isMe: isMeMsg,
      child: GestureDetector(
        onTap: () {
          if (listType == null || ownerId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This shared list is unavailable')),
            );
            return;
          }

          if (listType == 'custom' && listId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SharedListDetailsPage(
                  ownerId: ownerId,
                  listId: listId,
                  listName: listName,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SharedSpecialListPage(
                  ownerId: ownerId,
                  listType: listType,
                  listName: listName,
                ),
              ),
            );
          }
        },

        // 👇 ONE SINGLE BLOCK
        child: ChatListBubblePreview(
          ownerId: ownerId!,
          listType: listType!,
          listId: listId,
          listName: listName,
        ),
      ),
    ),
  );
}


    return const SizedBox.shrink();
  }

  // ------------------- UI -------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(other).snapshots(),
          builder: (_, snap) {
            final data = snap.data?.data();
            final name = (data?['username'] ?? 'User').toString();
            final photo = (data?['photoUrl'] ?? '').toString();

            if (_otherName != name) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _otherName = name);
              });
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chat.messagesStream(other),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await _chat.markSeen(other);
                });

                _scrollBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  clipBehavior: Clip.none,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final m = doc.data();

                    final senderId = (m['senderId'] ?? '').toString();
                    final isMeMsg = senderId == me;

                    final type = (m['type'] ?? 'text').toString();
                    final text = (m['text'] ?? '').toString();
                    final imageUrl = (m['imageUrl'] ?? '').toString();
                    final voiceUrl = (m['voiceUrl'] ?? '').toString();
                    final deleted = m['deleted'] == true;

                    final replyToText = (m['replyToText'] ?? '').toString();
                    final replyToSender = (m['replyToSender'] ?? '').toString();
                    final hasReply = replyToText.isNotEmpty;

                    final rawSeenBy = m['seenBy'];
                    final List<String> seenBy = (rawSeenBy is List)
                        ? rawSeenBy.map((e) => e.toString()).toList()
                        : <String>[];
                    final bool seenByOther = seenBy.contains(other);

                    final rawReactions = m['reactions'];
                    final Map<String, dynamic> reactions = (rawReactions is Map<String, dynamic>)
                        ? rawReactions
                        : (rawReactions is Map)
                            ? Map<String, dynamic>.from(rawReactions)
                            : <String, dynamic>{};

                    final bool showSeen = isMeMsg && seenByOther && i == docs.length - 1;

                    return KeyedSubtree(
                      key: ValueKey(doc.id),
                      child: Align(
                        alignment: isMeMsg ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: reactions.isNotEmpty ? 14 : 0),
                          child: Builder(
                            builder: (bubbleContext) {
                              return Column(
                                crossAxisAlignment:
                                    isMeMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  _buildMessage(
                                    bubbleContext: bubbleContext,
                                    type: type,
                                    text: text,
                                    imageUrl: imageUrl,
                                    voiceUrl: voiceUrl,
                                    deleted: deleted,
                                    isMeMsg: isMeMsg,
                                    messageId: doc.id,
                                    replyToText: hasReply ? replyToText : null,
                                    replyToSender: hasReply ? replyToSender : null,
                                    m: m,
                                  ),
                                  if (reactions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _ReactionBadge(reactions),
                                    ),
                                  if (showSeen)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4, right: 6),
                                      child: Text(
                                        'Seen',
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // reply preview
          if (_replyToMessageId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reply to ${_replyToSender ?? ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearReply,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

          // voice preview OR input
          if (_hasVoicePreview)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _deleteVoicePreview,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Voice message • ${_fmt(_recordDuration)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFE5A3A3)),
                    onPressed: _sendVoice,
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white70),
                      onPressed: () => _sendPickedImage(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.white70),
                      onPressed: () => _sendPickedImage(ImageSource.gallery),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.redAccent : Colors.white70,
                      ),
                      onPressed: () async {
                        if (_isRecording) {
                          await _stopRecording();
                        } else {
                          await _startRecording();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFE5A3A3)),
                      onPressed: _sendText,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------- REACTIONS UI -------------------

class _ReactionBadge extends StatelessWidget {
  final Map<String, dynamic> reactions;
  const _ReactionBadge(this.reactions, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emojis = reactions.values.map((e) => e.toString()).toSet().join(' ');
    final count = reactions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emojis, style: const TextStyle(fontSize: 14)),
          if (count > 1)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  final Function(String) onSelect;
  const _ReactionPill({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉'];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...emojis.map(
              (e) => GestureDetector(
                onTap: () => onSelect(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final emoji = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.black,
                  builder: (_) => const _EmojiPickerSheet(),
                );
                if (emoji != null) onSelect(emoji);
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () => onSelect(''), // remove
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  static const emojis = [
    '😀','😁','😂','🤣','😍','😘','😭','😡','👍','👎','🔥','🎉','❤️','💔','👏','🙏','😮','😢',
    '😎','🤔','😴','🤯','🥳','🤩','💯','✅','❌','⭐️','🌙','⚡️','🎬','🍿',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GridView.count(
        crossAxisCount: 6,
        padding: const EdgeInsets.all(12),
        children: emojis
            .map(
              (e) => GestureDetector(
                onTap: () => Navigator.pop(context, e),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ------------------- VOICE PLAYER -------------------

class VoicePlaybackController {
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<String?> activeMessageId = ValueNotifier<String?>(null);

  String? _activeUrl;

  Future<void> play({required String messageId, required String url}) async {
    if (url.isEmpty) return;

    if (activeMessageId.value != null && activeMessageId.value != messageId) {
      await stop();
    }

    if (_activeUrl != url) {
      _activeUrl = url;
      await player.setUrl(url);
    }

    activeMessageId.value = messageId;
    await player.play();
  }

  Future<void> pause() async => player.pause();

  Future<void> stop() async {
    await player.stop();
    activeMessageId.value = null;
    _activeUrl = null;
  }

  bool isActive(String messageId) => activeMessageId.value == messageId;

  void dispose() {
    activeMessageId.dispose();
    player.dispose();
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String messageId;
  final String url;
  final VoicePlaybackController controller;
  final Color bubbleColor;

  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.url,
    required this.controller,
    required this.bubbleColor,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = widget.controller.player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  bool get _isThisActive => widget.controller.isActive(widget.messageId);

  bool get _isPlaying => _isThisActive && widget.controller.player.playing == true;

  Duration get _position => widget.controller.player.position;

  Duration get _duration => widget.controller.player.duration ?? Duration.zero;

  Future<void> _togglePlay() async {
    if (widget.url.isEmpty) return;

    if (_isPlaying) {
      await widget.controller.pause();
    } else {
      await widget.controller.play(messageId: widget.messageId, url: widget.url);
    }

    if (mounted) setState(() {});
  }

  Future<void> _seekTo(double seconds) async {
    final d = _duration;
    if (d == Duration.zero) return;

    await widget.controller.player.seek(Duration(seconds: seconds.round()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.player.positionStream,
      builder: (_, posSnap) {
        final pos = _isThisActive ? (posSnap.data ?? _position) : Duration.zero;

        return StreamBuilder<Duration?>(
          stream: widget.controller.player.durationStream,
          builder: (_, durSnap) {
            final dur = _isThisActive ? (durSnap.data ?? _duration) : Duration.zero;

            final totalSeconds =
                dur.inMilliseconds > 0 ? dur.inMilliseconds / 1000.0 : 0.0;
            final posSeconds =
                pos.inMilliseconds > 0 ? pos.inMilliseconds / 1000.0 : 0.0;

            final progress = (totalSeconds <= 0)
                ? 0.0
                : (posSeconds / totalSeconds).clamp(0.0, 1.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: 6),
                    _FakeWaveform(progress: progress, animate: _isPlaying),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6, top: 6),
                  child: Column(
                    children: [
                      Slider(
                        value: _isThisActive
                            ? posSeconds.clamp(0.0, totalSeconds)
                            : 0.0,
                        min: 0.0,
                        max: totalSeconds <= 0 ? 1.0 : totalSeconds,
                        onChanged: !_isThisActive ? null : (v) => _seekTo(v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isThisActive ? _fmt(pos) : '00:00',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _isThisActive ? _fmt(dur) : '00:00',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
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

class _FakeWaveform extends StatelessWidget {
  final double progress; // 0..1
  final bool animate;

  const _FakeWaveform({required this.progress, required this.animate});

  @override
  Widget build(BuildContext context) {
    const bars = 24;

    return SizedBox(
      width: 160,
      height: 28,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: animate ? 1 : 0),
        duration: const Duration(milliseconds: 500),
        builder: (_, t, __) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(bars, (i) {
              final base = 0.35 +
                  0.65 *
                      (0.5 +
                          0.5 * math.sin(i * 0.55 + (animate ? t * 6.0 : 0.0)));

              final h = 6 + base * 18;
              final barProgress = i / (bars - 1);
              final active = barProgress <= progress;

              return Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 3,
                    height: h,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
