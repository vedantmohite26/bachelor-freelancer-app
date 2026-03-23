import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:freelancer/features/jobs/screens/payment_received_screen.dart';

class HelperCompletedJobsScreen extends StatelessWidget {
  const HelperCompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Completed Jobs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jobService.getHelperCompletedJobs(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: colorScheme.error),
                  SizedBox(height: 16.h),
                  Text(
                    "Error loading jobs",
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64.sp,
                    color: colorScheme.outlineVariant,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "No completed jobs yet",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Complete jobs to see them here",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _CompletedJobCard(job: job);
            },
          );
        },
      ),
    );
  }
}

class _CompletedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const _CompletedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = job['title'] ?? 'Untitled Job';
    final price = (job['price'] ?? 0).toDouble();
    final status = job['status'] as String?;
    final isPending = status == 'payment_pending';

    final completedAtTimestamp = job['completedAt'];
    String dateText = 'Unknown date';

    if (isPending) {
      dateText = "Payment Pending";
    } else if (completedAtTimestamp != null) {
      try {
        final date = completedAtTimestamp.toDate();
        dateText = "Completed on ${DateFormat('MMM d, yyyy').format(date)}";
      } catch (e) {
        // ignore
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceivedScreen(
              amount: price,
              coins: (job['coinsEarned'] as num?)?.toDouble() ?? 0.0,
              points: (job['pointsEarned'] as num?)?.toInt() ?? 0,
              jobTitle: title,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isPending
                ? Colors.orange.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Icon(
                    isPending ? Icons.pending_actions : Icons.check_circle,
                    color: isPending ? Colors.orange : const Color(0xFF10B981),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        dateText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPending
                              ? Colors.orange
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isPending
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${price.toStringAsFixed(0)}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
