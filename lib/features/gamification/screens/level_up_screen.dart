import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';

import 'package:freelancer/core/theme/app_theme.dart';

class LevelUpScreen extends StatefulWidget {
  final int newLevel;
  final VoidCallback onContinue;

  const LevelUpScreen({
    super.key,
    required this.newLevel,
    required this.onContinue,
  });

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / Badge Icon with Animation
            RepaintBoundary(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.all(40.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.coinYellow,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.coinYellow.withValues(alpha: 0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    size: 100.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 48.h),

            // Text
            Text(
              "LEVEL UP!",
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "You are now Level ${widget.newLevel}",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "+50 Student Coins Earned",
              style: TextStyle(
                color: AppTheme.growthGreen,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 64.h),

            ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: 48.w,
                  vertical: 16.h,
                ),
              ),
              child: const Text("Keep Going"),
            ),
          ],
        ),
      ),
    );
  }
}
