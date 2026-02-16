import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/features/community/screens/friend_requests_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            "Activity",
            style: GoogleFonts.plusJakartaSans(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: null,
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Job Updates"),
              Tab(text: "Payments"),
              Tab(text: "Community"),
            ],
          ),
        ),
        body: TabBarView(
          children: [const _UpdatesList(), _PaymentsList(), _CommunityTab()],
        ),
      ),
    );
  }
}

class _UpdatesList extends StatelessWidget {
  const _UpdatesList();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final userId = authService.user?.uid;

    if (userId == null) return const Center(child: Text("Please login"));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: notificationService.getUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No new activity", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final type = notification['type'] ?? 'system';
            final timestamp =
                (notification['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final timeAgo = _formatTimeAgo(timestamp);

            return _ActivityItem(
              icon: _getIconForType(type),
              iconBgColor: _getColorForType(type).withValues(alpha: 0.1),
              iconColor: _getColorForType(type),
              title: notification['title'] ?? 'Notification',
              subtitle: notification['subtitle'] ?? '',
              time: timeAgo,
              isUnread: !(notification['isRead'] ?? true),
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'job':
        return Icons.work_outline;
      case 'payment':
        return Icons.payments_outlined;
      case 'message':
        return Icons.message_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'job':
        return AppTheme.primaryBlue;
      case 'payment':
        return AppTheme.growthGreen;
      case 'message':
        return AppTheme.coinYellow;
      default:
        return Colors.grey;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData? icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
  final Widget? trailing;

  const _ActivityItem({
    this.icon,
    this.iconBgColor,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor ?? colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (trailing != null)
                      trailing!
                    else
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = Provider.of<AuthService>(context, listen: false);
    final friendService = Provider.of<FriendService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) {
      return Center(
        child: Text(
          "Please login",
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Friend Requests Card
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: friendService.getIncomingRequestsStream(userId),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FriendRequestsScreen(),
                  ),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people, color: colorScheme.primary),
              ),
              title: Text(
                "Friend Requests",
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                count > 0 ? "$count new requests" : "No pending requests",
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(Icons.chevron_right, color: Colors.grey),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return const Center(child: Text("Please login"));

    return FutureBuilder<Map<String, dynamic>?>(
      future: userService.getUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userProfile = userSnapshot.data;
        final isSeeker = userProfile?['role'] != 'helper';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: paymentService.getUserPaymentsStream(
            userId,
            asSeeker: isSeeker,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data ?? [];

            if (payments.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No payment history",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final timestamp =
                    (payment['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final amount = (payment['amount'] ?? 0).toDouble();
                final isIncoming = !isSeeker; // Incoming if helper

                return _ActivityItem(
                  icon: isIncoming
                      ? Icons.arrow_downward
                      : Icons.arrow_upward, // Arrow down for receiving
                  iconBgColor: isIncoming
                      ? AppTheme.growthGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  iconColor: isIncoming ? AppTheme.growthGreen : Colors.red,
                  title: payment['jobTitle'] ?? 'Payment',
                  subtitle: isIncoming ? 'Received' : 'Paid',
                  time: _formatDate(timestamp),
                  trailing: Text(
                    "${isIncoming ? '+' : '-'}₹${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isIncoming ? AppTheme.growthGreen : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
