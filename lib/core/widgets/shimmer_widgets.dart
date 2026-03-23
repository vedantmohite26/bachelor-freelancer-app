import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ANIMATION — Shared base for all skeleton screens
// ─────────────────────────────────────────────────────────────────────────────

/// A pulsing shimmer effect widget. Wraps any child in a looping opacity
/// animation that simulates content loading — no external dependencies.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUILDING BLOCKS — Small reusable skeleton shapes
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSED SKELETONS — Drop-in replacements for loading states
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a single list-tile shaped item (chat, transaction, activity)
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          ShimmerCircle(size: 44.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14.h),
                SizedBox(height: 8.h),
                ShimmerBox(width: 120.w, height: 10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a card (job card, application card, gig card)
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerCircle(size: 40.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: double.infinity, height: 14.h),
                      SizedBox(height: 6.h),
                      ShimmerBox(width: 80.w, height: 10.h),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ShimmerBox(width: double.infinity, height: 12.h),
            SizedBox(height: 6.h),
            ShimmerBox(width: 200.w, height: 12.h),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 70.w, height: 24.h, borderRadius: 12),
                ShimmerBox(width: 60.w, height: 24.h, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a stat card (coins, tasks done)
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 44.w, height: 44.h, borderRadius: 12),
          SizedBox(height: 12.h),
          ShimmerBox(width: 80.w, height: 12.h),
          SizedBox(height: 6.h),
          ShimmerBox(width: 50.w, height: 20.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL-SCREEN SKELETONS — Replace entire screen loading states
// ─────────────────────────────────────────────────────────────────────────────

/// Full skeleton for the Helper Dashboard
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 60.h,
                bottom: 30.h,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160.w, height: 28.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 120.w, height: 14.h),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // Earnings card shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ShimmerBox(
                width: double.infinity,
                height: 90.h,
                borderRadius: 16,
              ),
            ),
            SizedBox(height: 16.h),
            // Stats row shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  const Expanded(child: ShimmerStatCard()),
                  SizedBox(width: 16.w),
                  const Expanded(child: ShimmerStatCard()),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Section header shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ShimmerBox(width: 160.w, height: 18.h),
            ),
            SizedBox(height: 12.h),
            // Card list shimmer
            const ShimmerCard(),
            const ShimmerCard(),
          ],
        ),
      ),
    );
  }
}

/// Full skeleton for a list-based screen (jobs, activity, chat)
class ShimmerListScreen extends StatelessWidget {
  final int itemCount;
  const ShimmerListScreen({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, _) => const ShimmerCard(),
      ),
    );
  }
}

/// Full skeleton for profile screens
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              ShimmerCircle(size: 100.sp),
              SizedBox(height: 16.h),
              ShimmerBox(width: 140.w, height: 20.h),
              SizedBox(height: 8.h),
              ShimmerBox(width: 100.w, height: 14.h),
              SizedBox(height: 32.h),
              ShimmerBox(
                width: double.infinity,
                height: 56.h,
                borderRadius: 12,
              ),
              SizedBox(height: 16.h),
              ShimmerBox(
                width: double.infinity,
                height: 56.h,
                borderRadius: 12,
              ),
              SizedBox(height: 16.h),
              ShimmerBox(
                width: double.infinity,
                height: 56.h,
                borderRadius: 12,
              ),
              SizedBox(height: 16.h),
              ShimmerBox(
                width: double.infinity,
                height: 56.h,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Finance Dashboard
class ShimmerFinanceDashboard extends StatelessWidget {
  const ShimmerFinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              // Summary card
              ShimmerBox(
                width: double.infinity,
                height: 140.h,
                borderRadius: 16,
              ),
              SizedBox(height: 20.h),
              // Budget card
              ShimmerBox(
                width: double.infinity,
                height: 200.h,
                borderRadius: 16,
              ),
              SizedBox(height: 20.h),
              // Chart placeholder
              ShimmerBox(
                width: double.infinity,
                height: 180.h,
                borderRadius: 16,
              ),
              SizedBox(height: 20.h),
              // Transaction list
              ShimmerBox(width: 140.w, height: 18.h),
              SizedBox(height: 12.h),
              const ShimmerListTile(),
              const ShimmerListTile(),
              const ShimmerListTile(),
              const ShimmerListTile(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Seeker Home Tab (helper cards grid)
class ShimmerSeekerHome extends StatelessWidget {
  const ShimmerSeekerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header area
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 60.h,
                bottom: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 180.w, height: 28.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 240.w, height: 14.h),
                  SizedBox(height: 16.h),
                  // Search bar
                  ShimmerBox(
                    width: double.infinity,
                    height: 48.h,
                    borderRadius: 24,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            // Category chips
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  ShimmerBox(width: 80.w, height: 32.h, borderRadius: 16),
                  SizedBox(width: 8.w),
                  ShimmerBox(width: 90.w, height: 32.h, borderRadius: 16),
                  SizedBox(width: 8.w),
                  ShimmerBox(width: 70.w, height: 32.h, borderRadius: 16),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Helper card skeletons
            const ShimmerCard(),
            const ShimmerCard(),
            const ShimmerCard(),
          ],
        ),
      ),
    );
  }
}
