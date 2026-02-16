import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final senderId = authService.user?.uid;

    if (senderId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: senderId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.otherUserName), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet. Say hi!",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Show newest at the bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;
                    return _MessageBubble(
                      message: msg['content'] ?? '',
                      isMe: isMe,
                      time: (msg['timestamp'] as Timestamp?)?.toDate(),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(child: _buildInputArea()),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ), // Visual separator
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: 0.1,
            ), // Increased opacity
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? time;

  const _MessageBubble({required this.message, required this.isMe, this.time});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primaryBlue
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(time!),
                style: TextStyle(
                  color: isMe ? Colors.white70 : colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
