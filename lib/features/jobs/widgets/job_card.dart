import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/features/jobs/screens/job_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class JobCard extends StatelessWidget {
  final String title;
  final num price;
  final String distance;
  final String category;
  final String time;
  final Map<String, dynamic> jobData;

  const JobCard({
    super.key,
    required this.title,
    required this.price,
    required this.distance,
    required this.category,
    required this.time,
    required this.jobData,
    this.isApplied = false,
  });

  final bool isApplied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surface;
    final secondaryCardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: jobData)),
          );
        },
        child: Container(
          // margin: EdgeInsets.only(bottom: 8.h), // Removed to rely on ListView separator
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondaryCardColor,
                                    borderRadius: BorderRadius.circular(8.w),
                                  ),
                                  child: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Payment Type Chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: (jobData['priceType'] == 'hourly')
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                child: Text(
                                  (jobData['priceType'] == 'hourly')
                                      ? 'Hourly'
                                      : 'Fixed',
                                  style: TextStyle(
                                    color: (jobData['priceType'] == 'hourly')
                                        ? Colors.orange
                                        : Colors.blue,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  distance,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              if (jobData['priceType'] == 'hourly') ...[
                                Icon(
                                  Icons.access_time,
                                  size: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  time, // Duration string
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Swipe to Apply Area
              if (isApplied)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: secondaryCardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                      SizedBox(width: 8.w),
                      Text(
                        "Applied",
                        style: TextStyle(
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (direction) async {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final user = authService.user;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login to apply")),
                      );
                      return false;
                    }

                    // Capture providers before going async
                    final jobService = Provider.of<JobService>(
                      context,
                      listen: false,
                    );
                    final notificationService =
                        Provider.of<NotificationService>(
                          context,
                          listen: false,
                        );
                    final userService = Provider.of<UserService>(
                      context,
                      listen: false,
                    );
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // Fire-and-forget: run apply logic asynchronously
                    // so the Dismissible snaps back instantly.
                    // The parent's Firestore stream will flip isApplied â†’ true.
                    () async {
                      try {
                        await jobService.applyForJob(jobData['id'], user.uid);

                        // Notify the seeker (non-blocking)
                        final helperProfile = await userService.getUserProfile(
                          user.uid,
                        );
                        final helperName = helperProfile?['name'] ?? 'A helper';
                        final posterId = jobData['posterId'] as String?;
                        if (posterId != null) {
                          notificationService.createNotification(
                            userId: posterId,
                            title: 'New Application',
                            subtitle:
                                '$helperName applied for "${jobData['title']}"',
                            type: 'job',
                            relatedId: jobData['id'],
                          );
                        }

                        // Show success popup
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.w),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(28.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72.w,
                                      height: 72.h,
                                      decoration: BoxDecoration(
                                        color: AppTheme.growthGreen.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppTheme.growthGreen,
                                        size: 40.sp,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Text(
                                      "Application Sent!",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Your application for \"${jobData['title']}\" has been submitted. The seeker will review it shortly.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        fontSize: 14.sp,
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 14.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Great!",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text("Error: ${e.toString()}")),
                        );
                      }
                    }();

                    return false; // Return immediately â€” don't freeze the swipe
                  },
                  background: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20.w),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8.w),
                        const Text(
                          "Applied!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: jobData),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Swipe to Apply",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.keyboard_double_arrow_right,
                            color: colorScheme.onPrimary,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
