import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';
import 'package:freelancer/features/chat/screens/new_chat_screen.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view messages")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), elevation: 0),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_list_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No messages yet",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Ideally we pass the name, but for now we'll let ChatScreen fetch it or show generic
              // Using "Chat" as default title if name is not immediately available
              const otherUserName = "User";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat['id'],
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                },
                child: _ChatListItem(
                  participants: chat['participants'] ?? [],
                  currentUserId: currentUserId,
                  message: chat['lastMessage'] ?? '',
                  time: _formatTimeAgo(
                    (chat['lastMessageTime'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                  ),
                  unread: false, // Implement read status logic if needed
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class _ChatListItem extends StatelessWidget {
  final List<dynamic> participants;
  final String currentUserId;
  final String message;
  final String time;
  final bool unread;

  const _ChatListItem({
    required this.participants,
    required this.currentUserId,
    required this.message,
    required this.time,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );
    final userService = Provider.of<UserService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: userService.getUserProfile(otherUserId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?['name'] ?? 'User';
        final profilePic = user?['profilePic'];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CachedNetworkAvatar(
                imageUrl: profilePic,
                radius: 20,
                fallbackText: name,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                fallbackIconColor: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? AppTheme.textDark : AppTheme.textLight,
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
