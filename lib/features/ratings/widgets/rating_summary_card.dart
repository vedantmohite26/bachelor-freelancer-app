import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/rating_service.dart';

class RatingSummaryCard extends StatelessWidget {
  final String helperId;
  final double averageRating;
  final int reviewCount;
  final bool compact; // Option to hide bars if needed, but default false

  const RatingSummaryCard({
    super.key,
    required this.helperId,
    required this.averageRating,
    required this.reviewCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) return const SizedBox.shrink();

    final ratingService = Provider.of<RatingService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big Rating Number
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color(0xFFFBBF24),
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reviewCount ${reviewCount == 1 ? 'Review' : 'Reviews'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Rating Bars
              Expanded(
                child: FutureBuilder<Map<int, int>>(
                  future: ratingService.getRatingDistribution(helperId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final distribution = snapshot.data!;
                    final maxCount = reviewCount > 0 ? reviewCount : 1;

                    return Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = distribution[star] ?? 0;
                        final percentage = maxCount > 0
                            ? count / maxCount
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12,
                                child: Text(
                                  '$star',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage.toDouble(),
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    color: const Color(0xFFFBBF24),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
