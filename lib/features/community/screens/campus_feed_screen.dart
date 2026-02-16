import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

import 'package:freelancer/features/community/screens/leaderboard_screen.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';

class CampusFeedScreen extends StatelessWidget {
  const CampusFeedScreen({super.key});

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreatePostDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityService = Provider.of<CommunityService>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Campus Community",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Helper by Email',
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.leaderboard_outlined, color: colorScheme.primary),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Community notifications coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'campus_feed_fab',
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: communityService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No posts yet. Be the first!",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              final timestamp =
                  (post['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return _PostCard(
                key: ValueKey(post['id']),
                authorName: post['authorName'] ?? 'Student',
                timeAgo: _formatTimeAgo(timestamp),
                content: post['content'] ?? '',
                isOfficial: post['isOfficial'] ?? false,
                likes: post['likes'] ?? 0,
                comments: post['comments'] ?? 0,
                postId: post['id'],
                authorId: post['authorId'],
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

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SearchUserDialog(),
    );
  }
}

class _SearchUserDialog extends StatefulWidget {
  const _SearchUserDialog();

  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundUser;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundUser = null;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = await userService.searchUserByEmail(email);

      if (mounted) {
        setState(() {
          _foundUser = user;
          if (user == null) {
            _errorMessage = "User not found";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error searching: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search Helper"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter Email ID",
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _isLoading ? null : _search,
              ),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(),
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          if (_foundUser != null) _buildUserCard(context, _foundUser!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    return Card(
      child: ListTile(
        leading: CachedNetworkAvatar(
          imageUrl: user['profilePic'],
          radius: 20,
          fallbackText: user['name'] ?? '?',
          backgroundColor: AppTheme.primaryBlue,
          fallbackIconColor: Colors.white,
        ),
        title: Text(user['name'] ?? 'Unknown'),
        subtitle: Text(user['role'] ?? 'User'),
        trailing: ElevatedButton(
          onPressed: () {
            // Navigate to helper profile to connect
            Navigator.pop(context); // Close dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HelperProfileScreen(helperId: user['id']),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text("Connect"),
        ),
      ),
    );
  }
}

class _CreatePostDialog extends StatefulWidget {
  const _CreatePostDialog();

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final communityService = Provider.of<CommunityService>(
      context,
      listen: false,
    );
    final userService = Provider.of<UserService>(context, listen: false);

    final user = authService.user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Fetch user name for the post
      final userProfile = await userService.getUserProfile(user.uid);
      final userName = userProfile?['name'] ?? 'Student';
      // Official if from Student Council (mock logic for now)
      final isOfficial = userName == "Student Council";

      await communityService.createPost(
        content: _controller.text,
        userId: user.uid,
        userName: userName,
        isOfficial: isOfficial,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error posting: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Post"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: "What's on your mind?",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Post"),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String content;
  final bool isOfficial;
  final int likes;
  final int comments;
  final String postId;
  final String? authorId;

  const _PostCard({
    super.key,
    required this.authorName,
    required this.timeAgo,
    required this.content,
    required this.isOfficial,
    required this.likes,
    required this.comments,
    required this.postId,
    this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final communityService = Provider.of<CommunityService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: Colors.grey.shade100), // Clean UI
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isOfficial
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade300,
                radius: 20,
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isOfficial ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isOfficial)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (currentUserId != null) {
                    communityService.toggleLike(postId, currentUserId);
                  }
                },
                child: _ActionBtn(icon: Icons.favorite_border, label: "$likes"),
              ),
              const SizedBox(width: 24),
              _ActionBtn(icon: Icons.chat_bubble_outline, label: "$comments"),
              const Spacer(),
              const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
