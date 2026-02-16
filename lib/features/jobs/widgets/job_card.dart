import 'package:flutter/material.dart';
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
          // margin: const EdgeInsets.only(bottom: 8), // Removed to rely on ListView separator
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(20),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondaryCardColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Payment Type Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (jobData['priceType'] == 'hourly')
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (jobData['priceType'] == 'hourly')
                                      ? 'Hourly'
                                      : 'Fixed',
                                  style: TextStyle(
                                    color: (jobData['priceType'] == 'hourly')
                                        ? Colors.orange
                                        : Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  distance,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (jobData['priceType'] == 'hourly') ...[
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time, // Duration string
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 22,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: secondaryCardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                      SizedBox(width: 8),
                      Text(
                        "Applied",
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                    final user = authService.user;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login to apply")),
                      );
                      return false;
                    }

                    try {
                      await jobService.applyForJob(jobData['id'], user.uid);

                      // Notify the seeker
                      final helperProfile = await userService.getUserProfile(
                        user.uid,
                      );
                      final helperName = helperProfile?['name'] ?? 'A helper';
                      final posterId = jobData['posterId'] as String?;
                      if (posterId != null) {
                        await notificationService.createNotification(
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
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppTheme.growthGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.growthGreen,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Application Sent!",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Your application for \"${jobData['title']}\" has been submitted. The seeker will review it shortly.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(ctx).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Great!",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: ${e.toString()}")),
                        );
                      }
                    }
                    return false; // Don't dismiss the widget
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
                    padding: const EdgeInsets.only(left: 20),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_double_arrow_right,
                            color: colorScheme.onPrimary,
                            size: 20,
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
