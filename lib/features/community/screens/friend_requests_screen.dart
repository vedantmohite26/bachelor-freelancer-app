import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final friendService = Provider.of<FriendService>(context, listen: false);
    final userId = authService.user?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Please login to view requests",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Friend Requests",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Show manage options
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Manage Friend Requests'),
                    content: const Text(
                      'Options: Block users, Clear all, Request settings',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                "Manage",
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(50),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(40),
                ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  _buildTab("Find", 0, icon: Icons.search),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: friendService.getIncomingRequestsStream(userId),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _buildTab("Received", count);
                    },
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: friendService.getSentRequestsStream(userId),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _buildTab("Sent", count);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _FindFriendsTab(userId: userId),
            _buildReceivedList(friendService, userId),
            _buildSentList(friendService, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, {IconData? icon}) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedList(FriendService friendService, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getIncomingRequestsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No received requests");
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length + 1, // +1 for Sync card
          itemBuilder: (context, index) {
            if (index == requests.length) return _buildSyncContactsCard();

            final req = requests[index];
            final date = (req['createdAt'] as Timestamp?)?.toDate();
            final timeAgo = date != null
                ? "${date.month}/${date.day} ${date.hour}:${date.minute}"
                : "Recently";

            return Column(
              children: [
                RequestCard(
                  key: ValueKey(req['requestId']),
                  requestId: req['requestId'], // Need requestId for actions
                  name: req['name'],
                  role: req['role'],
                  mutuals: 0, // Placeholder
                  time: timeAgo,
                  imageColor: Colors.blueAccent,
                  isSent: false,
                  profilePic: req['profilePic'],
                  onAccept: () =>
                      friendService.acceptFriendRequest(req['requestId']),
                  onReject: () =>
                      friendService.rejectFriendRequest(req['requestId']),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSentList(FriendService friendService, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getSentRequestsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No sent requests");
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final date = (req['createdAt'] as Timestamp?)?.toDate();
            final timeAgo = date != null
                ? "${date.month}/${date.day} ${date.hour}:${date.minute}"
                : "Recently";

            return Column(
              children: [
                RequestCard(
                  key: ValueKey(req['requestId']),
                  requestId: req['requestId'],
                  name: req['name'],
                  role: req['role'],
                  mutuals: 0,
                  time: timeAgo,
                  imageColor: Colors.grey,
                  isSent: true,
                  profilePic: req['profilePic'],
                  onCancel: () => friendService.cancelFriendRequest(
                    userId,
                    req['receiverId'],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSyncContactsCard() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C3E50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.contacts,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sync your contacts",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Find people you already know on CampusGig",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact sync feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF324B66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text("Find Friends"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Center(
          child: Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

// Find Friends Tab with Real-Time Search
class _FindFriendsTab extends StatefulWidget {
  final String userId;
  const _FindFriendsTab({required this.userId});

  @override
  State<_FindFriendsTab> createState() => _FindFriendsTabState();
}

class _FindFriendsTabState extends State<_FindFriendsTab> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _emailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // minimal delay for "instant" feel but avoiding excessive reads
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debugging: Bypass network if query is "debug"
      if (query.toLowerCase() == 'debug') {
        setState(() {
          _isLoading = false;
          _searchResults = [
            {
              'id': 'debug_user',
              'name': 'Debug User',
              'email': 'debug@test.com',
              'profilePic': null,
              'role': 'TESTER',
            },
          ];
        });
        return;
      }

      final userService = Provider.of<UserService>(context, listen: false);
      final results = await userService.searchUsersByEmailPrefix(query);

      if (mounted) {
        setState(() {
          final allResults = results;
          // Filter out current user from results
          _searchResults = allResults
              .where((u) => u['id'] != widget.userId)
              .toList();

          if (_searchResults.isEmpty) {
            if (allResults.any((u) => u['id'] == widget.userId)) {
              _errorMessage = "You found yourself! Search for others.";
            } else {
              _errorMessage = "No users found matching \"$query\"";
            }
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Find Friends",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Search by email ID to instantly find connections",
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Start typing email address...",
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            onPressed: () {
                              _emailController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        // Search Results List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _errorMessage != null
                            ? Icons.search_off
                            : Icons.person_search,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? "Type an email to search",
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(_searchResults[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final friendService = Provider.of<FriendService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HelperProfileScreen(helperId: user['id']),
                ),
              );
            },
            child: CachedNetworkAvatar(
              imageUrl:
                  user['profilePic'] != null && user['profilePic'].isNotEmpty
                  ? user['profilePic']
                  : null,
              radius: 26,
              backgroundColor: colorScheme.surfaceContainerHighest,
              fallbackText: user['name'] ?? 'U',
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user['role'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      user['role'],
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Action Button
          if (user['id'] != 'debug_user')
            StreamBuilder<FriendStatus>(
              stream: friendService.getFriendStatusStream(
                widget.userId,
                user['id'],
              ),
              builder: (context, snapshot) {
                final status = snapshot.data ?? FriendStatus.none;

                if (status == FriendStatus.connected) {
                  return OutlinedButton(
                    onPressed: () {
                      // Navigate to chat or profile
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      "Friends",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  );
                } else if (status == FriendStatus.pendingSent) {
                  return OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      "Requested",
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                return FilledButton(
                  onPressed: () {
                    friendService.sendFriendRequest(widget.userId, user['id']);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    "Connect",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class RequestCard extends StatefulWidget {
  final String requestId;
  final String name;
  final String role;
  final int mutuals;
  final String time;
  final Color imageColor;
  final bool isSent;
  final String? profilePic;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final Future<void> Function()? onCancel;

  const RequestCard({
    super.key,
    required this.requestId,
    required this.name,
    required this.role,
    required this.mutuals,
    required this.time,
    required this.imageColor,
    required this.isSent,
    this.profilePic,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isLoading = false;
  String? _statusMessage; // "Confirmed", "Deleted", "Cancelled"
  Color? _statusColor;

  Future<void> _handleAction(
    Future<void> Function()? action,
    String successMessage,
    Color color,
  ) async {
    if (action == null) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await action();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = successMessage;
          _statusColor = color;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_statusMessage != null) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _statusColor!.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _statusColor!.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _statusColor),
            const SizedBox(width: 8),
            Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CachedNetworkAvatar(
                imageUrl: widget.profilePic,
                radius: 24,
                backgroundColor: widget.imageColor,
                fallbackText: widget.name,
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
                          widget.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.time,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (widget.isSent)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleAction(
                  widget.onCancel,
                  "Request Cancelled",
                  Colors.grey,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text("Cancel Request"),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(
                      widget.onAccept,
                      "Confirmed",
                      Colors.green,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text("Confirm"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _handleAction(widget.onReject, "Deleted", Colors.red),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
