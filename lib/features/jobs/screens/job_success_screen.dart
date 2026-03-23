import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/features/maps/screens/map_screen.dart';

class JobSuccessScreen extends StatefulWidget {
  const JobSuccessScreen({super.key});

  @override
  State<JobSuccessScreen> createState() => _JobSuccessScreenState();
}

class _JobSuccessScreenState extends State<JobSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late AnimationController _checkController;
  late Animation<double> _glowAnimation;
  late Animation<double> _checkScaleAnimation;
  final List<Confetti> _confetti = [];

  @override
  void initState() {
    super.initState();

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Check mark scale animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkScaleAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkController.forward();

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Generate confetti particles
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _confetti.add(
        Confetti(
          x: random.nextDouble(),
          y: -random.nextDouble() * 0.3,
          color: _getRandomConfettiColor(random),
          rotation: random.nextDouble() * 360,
          size: random.nextDouble() * 8 + 4,
          velocity: random.nextDouble() * 2 + 1,
        ),
      );
    }
    _confettiController.forward();
  }

  Color _getRandomConfettiColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _glowController.dispose();
    _confettiController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Job Success",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Animated Success Icon with Confetti
              SizedBox(
                height: 250.h,
                width: 250.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Confetti particles
                    AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(250, 250),
                          painter: ConfettiPainter(
                            confetti: _confetti,
                            progress: _confettiController.value,
                          ),
                        );
                      },
                    ),

                    // Glowing circle
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 160.h,
                          width: 160.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(
                                  0xFF4ADE80,
                                ).withValues(alpha: 0.3 * _glowAnimation.value),
                                const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.1 * _glowAnimation.value),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        );
                      },
                    ),

                    // Check mark with scale animation
                    ScaleTransition(
                      scale: _checkScaleAnimation,
                      child: Container(
                        height: 110.h,
                        width: 110.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 60.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Bottom Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F2E),
                  borderRadius: BorderRadius.circular(32.w),
                ),
                child: Column(
                  children: [
                    Text(
                      "Job Posted Successfully!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      "Your request has been broadcasted.\nHelpers near you will be notified shortly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Map Screen to see nearby helpers/jobs
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapScreen(
                                onToggleView: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.w),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_outlined),
                            SizedBox(width: 8.w),
                            Text(
                              "View on Map",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        icon: Icon(Icons.home_outlined, size: 20.sp),
                        label: Text(
                          "Go to Home",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white24, width: 1.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.w),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

// Confetti data model
class Confetti {
  final double x;
  final double y;
  final Color color;
  final double rotation;
  final double size;
  final double velocity;

  Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.rotation,
    required this.size,
    required this.velocity,
  });
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;

  ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in confetti) {
      final paint = Paint()..color = particle.color;

      // Calculate position based on progress
      final x = particle.x * size.width;
      final y =
          particle.y * size.height +
          (progress * size.height * particle.velocity);

      // Only draw if still visible
      if (y < size.height) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(particle.rotation * progress);

        // Draw confetti as small rectangles
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size / 2,
        );
        canvas.drawRect(rect, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
