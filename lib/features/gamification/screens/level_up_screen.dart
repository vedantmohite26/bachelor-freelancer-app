import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / Badge Icon with Animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(40),
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
                child: const Icon(
                  Icons.stars_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Text
            Text(
              "LEVEL UP!",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You are now Level ${widget.newLevel}",
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              "+50 Student Coins Earned",
              style: TextStyle(
                color: AppTheme.growthGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 64),

            // Continue Button
            ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
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
