import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final overallRating = (review['overallRating'] as num).toDouble();
    final feedback = review['feedback'] as String?;
    final tags =
        (review['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final createdAt = review['createdAt']; // Timestamp

    final seekerId = review['seekerId'] as String? ?? '';
    final userService = Provider.of<UserService>(context, listen: false);

    DateTime date;
    if (createdAt != null) {
      // cloud_firestore Timestamp
      try {
        date = createdAt.toDate();
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    final dateStr = DateFormat('MMM d, yyyy').format(date);

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: userService.getUserProfile(seekerId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final name = user?['name'] ?? 'Verified User';
                    final photoUrl = user?['photoUrl'] as String?;

                    return Row(
                      children: [
                        CachedNetworkAvatar(
                          imageUrl: photoUrl,
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          fallbackIconColor: colorScheme.onPrimaryContainer,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14.sp, color: const Color(0xFFFBBF24)),
                    SizedBox(width: 4.w),
                    Text(
                      overallRating.toStringAsFixed(1),
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                      child: Text(
                        tag,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (feedback != null && feedback.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(feedback, style: textTheme.bodyMedium),
          ],
        ],
      ),
    ));
  }
}
