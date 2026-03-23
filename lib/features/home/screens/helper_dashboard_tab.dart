import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/features/jobs/screens/active_job_screen.dart';
import 'package:freelancer/features/community/screens/leaderboard_screen.dart';
import 'package:freelancer/features/wallet/screens/coin_shop_screen.dart';
import 'package:freelancer/features/safety/screens/safety_center_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';
import 'package:freelancer/features/jobs/screens/helper_completed_jobs_screen.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';

class HelperDashboardTab extends StatefulWidget {
  const HelperDashboardTab({super.key});

  @override
  State<HelperDashboardTab> createState() => _HelperDashboardTabState();
}

class _HelperDashboardTabState extends State<HelperDashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final jobService = Provider.of<JobService>(context, listen: false);
    final userId = authService.user?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton(
        heroTag: 'helper_dashboard_fab',
        onPressed: () => _showSafetyOptions(context),
        backgroundColor: const Color(0xFFEF4444), // Red for emergency
        child: const Icon(Icons.security, color: Colors.white),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: userService.getUserProfileStream(userId),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerDashboard();
          }

          final profile = profileSnapshot.data ?? {};
          final isOnline = profile['isOnline'] ?? false;
          final todaysEarnings = (profile['todaysEarnings'] ?? 0.0).toDouble();
          final gigsCompleted = profile['gigsCompleted'] ?? 0;
          final coins = profile['coins'] ?? 0;

          return CustomScrollView(
            slivers: [
              // Vibrant Header with Gradient
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 60.h, // Safe area top
                    bottom: 30.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1E40AF),
                      ], // Vibrant Blue
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dashboard",
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Container(
                                    width: 8.w,
                                    height: 8.h,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? const Color(0xFF10B981) // Green
                                          : Colors.white54,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isOnline
                                        ? "You're Online"
                                        : "You're Offline",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isOnline
                                          ? const Color(0xFF10B981)
                                          : Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => _navigateToMessages(context),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.emoji_events,
                                color: const Color(0xFFF59E0B),
                                size: 28.sp,
                              ),
                              onPressed: () => _showGamificationMenu(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // Key Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // Earnings (Real Money)
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(color: colorScheme.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              child: Icon(
                                Icons.payments,
                                color: const Color(0xFF10B981),
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Earnings",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  "₹${todaysEarnings.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Coins and Tasks
                      Row(
                        children: [
                          // Coin Balance
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.monetization_on,
                              iconColor: Colors.amber,
                              label: "Coin Balance",
                              value: "$coins",
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Tasks Completed
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HelperCompletedJobsScreen(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                icon: Icons.check_circle,
                                iconColor: AppTheme.primaryBlue,
                                label: "Tasks Done",
                                value: "$gigsCompleted",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 24.h)),

              // Active Applications Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Text(
                        "Active Applications",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Add view all if needed
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // Applications List
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: jobService.getHelperApplications(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Column(children: [ShimmerCard(), ShimmerCard()]),
                    );
                  }

                  final applications = snapshot.data ?? [];

                  if (applications.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              const Text(
                                'No active applications',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final application = applications[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 6.h,
                        ),
                        child: _ApplicationCard(
                          title: "Application #${index + 1}",
                          category: "General",
                          timeAgo: "2 hours ago",
                          status: application['status'] ?? 'pending',
                        ),
                      );
                    }, childCount: applications.length),
                  );
                },
              ),

              SliverToBoxAdapter(child: SizedBox(height: 24.h)),

              // Upcoming Gigs Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    "Upcoming Gigs",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // Upcoming Gigs List
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: jobService.getHelperUpcomingGigs(userId),
                builder: (context, snapshot) {
                  final gigs = snapshot.data ?? [];

                  if (gigs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(30.w),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              const Text(
                                'No upcoming gigs',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final gig = gigs[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 6.h,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveJobScreen(
                                  initialJobId: gig['id'],
                                  isSeeker: false,
                                ),
                              ),
                            );
                          },
                          child: _UpcomingGigCard(
                            title: gig['title'] ?? 'Gig',
                            category: gig['category'] ?? 'General',
                            price: (gig['price'] ?? 0.0).toDouble(),
                            time: gig['time'] ?? 'TBD',
                            status: gig['status'] ?? 'assigned',
                          ),
                        ),
                      );
                    }, childCount: gigs.length),
                  );
                },
              ),

              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          );
        },
      ),
    );
  }

  void _navigateToMessages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _showGamificationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: const Color(0xFFF59E0B),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gamification Hub",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Earn rewards and climb the ranks",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildGamificationCard(
                context,
                title: "Helper Leaderboard",
                subtitle: "Check your rank and stats",
                icon: Icons.emoji_events,
                color: Colors.amber,
                gradientColors: [
                  const Color(0xFFF59E0B),
                  const Color(0xFFD97706),
                ],
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              _buildGamificationCard(
                context,
                title: "Rewards Shop",
                subtitle: "Redeem your hard-earned coins",
                icon: Icons.shopping_bag,
                color: Colors.purple,
                gradientColors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
                ],
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoinShopScreen()),
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGamificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.w),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showSafetyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      color: const Color(0xFFEF4444),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Safety Shield",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Quick access to emergency tools",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _SafetyOptionButton(
                      icon: Icons.call,
                      label: "SOS Call",
                      color: const Color(0xFFEF4444),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet

                        final Uri launchUri = Uri(scheme: 'tel', path: '112');
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not launch dialer"),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _SafetyOptionButton(
                      icon: Icons.help_center,
                      label: "Help Center",
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SafetyCenterScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SafetyOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SafetyOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String category;
  final String timeAgo;
  final String status;

  const _ApplicationCard({
    required this.title,
    required this.category,
    required this.timeAgo,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Icon(
              Icons.work_outline,
              color: AppTheme.primaryBlue,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingGigCard extends StatelessWidget {
  final String title;
  final String category;
  final double price;
  final String time;
  final String status;

  const _UpcomingGigCard({
    required this.title,
    required this.category,
    required this.price,
    required this.time,
    required this.status,
  });

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'payment_pending':
        return const Color(0xFFEC4899);
      default:
        // For 'assigned', maybe use primary color or grey
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'payment_pending':
        return 'PAYMENT PENDING';
      default:
        return 'UPCOMING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "₹${price.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.w),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2.w),
                ),
                child: Column(
                  children: [
                    Text(
                      "TODAY",
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      time.split(':')[0],
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      "PM",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
