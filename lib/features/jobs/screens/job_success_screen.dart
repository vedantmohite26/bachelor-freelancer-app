import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Success Icon with Confetti
              SizedBox(
                height: 350,
                width: 350,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Confetti particles
                    AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(350, 350),
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
                          height: 200,
                          width: 200,
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
                        height: 140,
                        width: 140,
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
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F2E),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Job Posted Successfully!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Your request has been broadcasted.\nHelpers near you will be notified shortly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined),
                            SizedBox(width: 8),
                            Text(
                              "View on Map",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // Pop until we reach the home screen (root)
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        "Go to Home",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
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
