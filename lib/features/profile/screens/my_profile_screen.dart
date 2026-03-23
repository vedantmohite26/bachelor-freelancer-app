import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/profile/screens/edit_profile_screen.dart';
import 'package:freelancer/features/search/screens/helper_scanning_gigs_screen.dart';
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:freelancer/features/ratings/widgets/rating_summary_card.dart';
import 'package:freelancer/features/jobs/screens/helper_completed_jobs_screen.dart';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final userId = authService.user?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          "My Profile",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: userService.getUserProfileStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerProfile();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Error loading profile'));
          }

          final profile = snapshot.data!;
          final name = profile['name'] ?? 'User';
          final email = profile['email'] ?? '';
          final isOnline = profile['isOnline'] ?? false;
          final totalEarnings = (profile['totalEarnings'] ?? 0.0).toDouble();
          final gigsCompleted = profile['gigsCompleted'] ?? 0;
          final rating = (profile['rating'] ?? 0.0).toDouble();
          final reviewCount = profile['reviewCount'] ?? 0;
          final photoUrl = profile['photoUrl'] as String?;
          final totalPoints = (profile['points'] ?? 0) as int;
          final skills =
              (profile['skills'] as List?)?.map((s) => s.toString()).toList() ??
              [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Card
                Container(
                  color: colorScheme.surface,
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CachedNetworkAvatar(
                            imageUrl: photoUrl,
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            fallbackIconColor: Colors.grey.shade400,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(width: 4.w, height: 4.h),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified,
                            color: AppTheme.primaryBlue,
                            size: 20.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      if (profile['university'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                color: Colors.grey,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  profile['university'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (profile['phoneNumber'] != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.grey, size: 16.sp),
                            SizedBox(width: 6.w),
                            Text(
                              profile['phoneNumber'],
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      SizedBox(height: 16.h),
                      // Online/Offline Toggle Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.wifi,
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnline
                                        ? "You are Online"
                                        : "You are Offline",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    isOnline
                                        ? "Receiving new gig offers"
                                        : "Not receiving gigs",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isOnline,
                              onChanged: (value) async {
                                if (value) {
                                  // Show scanning animation when going online
                                  bool scanning = true;

                                  // Start timer to auto-close screen after delay
                                  Future.delayed(const Duration(seconds: 3), () {
                                    if (scanning && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  });

                                  // Wait for screen to close (either by timer or user back)
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HelperScanningGigsScreen(),
                                    ),
                                  );

                                  scanning = false;
                                }

                                await userService.updateOnlineStatus(
                                  userId,
                                  value,
                                );
                              },
                              activeThumbColor: const Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (rating > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: const Color(0xFFFBBF24),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    " ($reviewCount)",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Stats Grid
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments,
                          label: "Earnings",
                          value: "₹${totalEarnings.toStringAsFixed(0)}",
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(width: 12.w),
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
                          child: _StatCard(
                            icon: Icons.check_circle,
                            label: "Completed",
                            value: "$gigsCompleted",
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // XP Progress Bar
                _XpProgressCard(totalPoints: totalPoints),

                SizedBox(height: 16.h),

                // Skills
                if (skills.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Skills",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .map(
                                (skill) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.w),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Reviews Section
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Reviews",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (reviewCount > 0)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HelperReviewsScreen(
                                      helperId: userId,
                                      averageRating: rating,
                                      reviewCount: reviewCount,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "See all",
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      if (rating > 0 && reviewCount > 0) ...[
                        RatingSummaryCard(
                          helperId: userId,
                          averageRating: rating,
                          reviewCount: reviewCount,
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Logout Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Confirm Dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Logout"),
                            content: const Text(
                              "Are you sure you want to logout?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authService.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/welcome',
                              (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 100.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Icon(icon, color: color, size: 32.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpProgressCard extends StatelessWidget {
  final int totalPoints;

  const _XpProgressCard({required this.totalPoints});

  // Level thresholds: 100 XP per level
  static const int xpPerLevel = 100;

  int get currentLevel => (totalPoints / xpPerLevel).floor();
  int get xpInCurrentLevel => totalPoints % xpPerLevel;
  int get xpNeededForNextLevel => xpPerLevel - xpInCurrentLevel;
  double get progress => xpInCurrentLevel / xpPerLevel;

  String _levelTitle(int level) {
    if (level < 3) return 'Beginner';
    if (level < 6) return 'Hustler';
    if (level < 10) return 'Pro';
    if (level < 15) return 'Expert';
    if (level < 25) return 'Master';
    return 'Legend';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = currentLevel;
    final title = _levelTitle(level);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level — $title',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$totalPoints XP total',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Level badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  'Lv.$level',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: SizedBox(
              height: 10.h,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // XP info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInCurrentLevel / $xpPerLevel XP',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$xpNeededForNextLevel XP to Level ${level + 1}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
