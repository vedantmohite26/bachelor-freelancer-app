import 'package:flutter/material.dart';

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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          ShimmerCircle(size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerCircle(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: double.infinity, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 12),
            SizedBox(height: 6),
            ShimmerBox(width: 200, height: 12),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 70, height: 24, borderRadius: 12),
                ShimmerBox(width: 60, height: 24, borderRadius: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 44, height: 44, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerBox(width: 80, height: 12),
          SizedBox(height: 6),
          ShimmerBox(width: 50, height: 20),
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
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 60,
                bottom: 30,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 28),
                  SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Earnings card shimmer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ShimmerBox(
                width: double.infinity,
                height: 90,
                borderRadius: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Stats row shimmer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: ShimmerStatCard()),
                  SizedBox(width: 16),
                  Expanded(child: ShimmerStatCard()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section header shimmer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ShimmerBox(width: 160, height: 18),
            ),
            const SizedBox(height: 12),
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
    return const ShimmerEffect(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 60),
              ShimmerCircle(size: 100),
              SizedBox(height: 16),
              ShimmerBox(width: 140, height: 20),
              SizedBox(height: 8),
              ShimmerBox(width: 100, height: 14),
              SizedBox(height: 32),
              ShimmerBox(width: double.infinity, height: 56, borderRadius: 12),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 56, borderRadius: 12),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 56, borderRadius: 12),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 56, borderRadius: 12),
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
    return const ShimmerEffect(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              // Summary card
              ShimmerBox(width: double.infinity, height: 140, borderRadius: 16),
              SizedBox(height: 20),
              // Budget card
              ShimmerBox(width: double.infinity, height: 200, borderRadius: 16),
              SizedBox(height: 20),
              // Chart placeholder
              ShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
              SizedBox(height: 20),
              // Transaction list
              ShimmerBox(width: 140, height: 18),
              SizedBox(height: 12),
              ShimmerListTile(),
              ShimmerListTile(),
              ShimmerListTile(),
              ShimmerListTile(),
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
    return const ShimmerEffect(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header area
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 60,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 180, height: 28),
                  SizedBox(height: 8),
                  ShimmerBox(width: 240, height: 14),
                  SizedBox(height: 16),
                  // Search bar
                  ShimmerBox(
                    width: double.infinity,
                    height: 48,
                    borderRadius: 24,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Category chips
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ShimmerBox(width: 80, height: 32, borderRadius: 16),
                  SizedBox(width: 8),
                  ShimmerBox(width: 90, height: 32, borderRadius: 16),
                  SizedBox(width: 8),
                  ShimmerBox(width: 70, height: 32, borderRadius: 16),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Helper card skeletons
            ShimmerCard(),
            ShimmerCard(),
            ShimmerCard(),
          ],
        ),
      ),
    );
  }
}
