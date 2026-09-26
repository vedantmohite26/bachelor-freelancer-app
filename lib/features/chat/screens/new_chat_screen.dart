import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  Stream<List<Map<String, dynamic>>>? _friendsStream;
  String? _cachedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    // FIX: Cache stream in state to prevent redundant stream allocations & re-subscriptions on widget rebuilds
    if (currentUserId != _cachedUserId) {
      _cachedUserId = currentUserId;
      if (currentUserId != null) {
        final friendService = Provider.of<FriendService>(context, listen: false);
        _friendsStream = friendService.getFriendsStream(currentUserId);
      } else {
        _friendsStream = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedUserId == null) {
      return const Scaffold(body: Center(child: Text("Please log in to chat")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("New Chat"), elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final friends = snapshot.data ?? [];

          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64.sp,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "No friends yet",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  const Text("Add friends from the Community tab!"),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: friends.length,
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return RepaintBoundary(
                child: _FriendListItem(
                  friend: friend,
                  onTap: () async {
                    try {
                      final chatService = Provider.of<ChatService>(
                        context,
                        listen: false,
                      );
                      final chatId = await chatService.createChat(
                        friend['id'],
                        _cachedUserId!,
                      );
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              otherUserName: friend['name'],
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error starting chat: $e")),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendListItem extends StatelessWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onTap;

  const _FriendListItem({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = friend['name'] ?? 'Unknown';
    final profilePic = friend['profilePic'];
    final role = friend['role'] ?? 'User';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
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
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
