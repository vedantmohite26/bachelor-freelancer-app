import 'package:flutter/material.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hello! I am your AI Assistant. How can I help you today?',
      'time': DateTime.now().subtract(const Duration(minutes: 1)),
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'isUser': true,
        'message': userMessage,
        'time': DateTime.now(),
      });
      _messageController.clear();
    });

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Mock AI Response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'message':
                "I'm a demo AI. I can't really process '$userMessage' yet, but I'm here to help!",
            'time': DateTime.now(),
          });
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Assistant",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Always here to help",
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return _ChatBubble(
                  message: msg['message'] as String,
                  isUser: isUser,
                  time: msg['time'] as DateTime,
                );
              },
            ),
          ),
          _buildInputArea(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Ask me anything...",
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic_none,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      // TODO: Implement voice input
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime time;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryBlue
              : (isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : colorScheme.onSurface,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
