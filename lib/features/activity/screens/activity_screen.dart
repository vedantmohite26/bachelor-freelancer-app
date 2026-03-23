import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/features/community/screens/friend_requests_screen.dart';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';

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
              fontSize: 14.sp,
            ),
            tabs: const [
              Tab(text: "Job Updates"),
              Tab(text: "Payments"),
              Tab(text: "Community"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_UpdatesList(), _PaymentsList(), _CommunityTab()],
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
          return const ShimmerListScreen();
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                const Text("No new activity", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${notifications.length} Updates",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All Updates?'),
                          content: const Text(
                            'This will permanently delete all your activity updates.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await notificationService.deleteAllUserNotifications(
                            userId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All updates cleared'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error clearing updates: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(Icons.delete_sweep, size: 20.sp),
                    label: const Text("Clear All"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
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
              ),
            ),
          ],
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
      margin: EdgeInsets.only(bottom: 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: iconBgColor ?? colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colorScheme.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),

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
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            SizedBox(width: 8.w),
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (trailing != null)
                      trailing!
                    else
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12.sp,
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
      padding: EdgeInsets.all(16.w),
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
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.w),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20.w),
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
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return const Center(child: Text("Please login"));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: paymentService.getAllUserPaymentsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerListScreen();
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                const Text(
                  "No payment history",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final timestamp =
                (payment['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final amount = (payment['amount'] ?? 0).toDouble();
            final isIncoming = payment['isIncoming'] == true;

            return _ActivityItem(
              icon: isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
              iconBgColor: isIncoming
                  ? AppTheme.growthGreen.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              iconColor: isIncoming ? AppTheme.growthGreen : Colors.red,
              title: payment['jobTitle'] ?? 'Payment',
              subtitle: isIncoming ? 'Earned (as Helper)' : 'Paid (as Seeker)',
              time: _formatDate(timestamp),
              trailing: Text(
                "${isIncoming ? '+' : '-'}₹${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: isIncoming ? AppTheme.growthGreen : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
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
