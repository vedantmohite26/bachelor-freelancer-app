import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freelancer/features/home/screens/home_screen.dart';

class PaymentReceivedScreen extends StatefulWidget {
  final double amount;
  final double coins;
  final int points;
  final String jobTitle;

  const PaymentReceivedScreen({
    super.key,
    required this.amount,
    required this.coins,
    required this.points,
    required this.jobTitle,
  });

  @override
  State<PaymentReceivedScreen> createState() => _PaymentReceivedScreenState();
}

class _PaymentReceivedScreenState extends State<PaymentReceivedScreen> {
  final List<_Confetti> _confettiList = [];

  @override
  void initState() {
    super.initState();
    _generateConfetti();
  }

  void _generateConfetti() {
    final random = math.Random();
    _confettiList.clear();
    for (int i = 0; i < 60; i++) {
      _confettiList.add(
        _Confetti(
          x: random.nextDouble(),
          y: random.nextDouble() * -1,
          speed: 1 + random.nextDouble() * 3,
          size: 4 + random.nextDouble() * 8,
          color: [
            const Color(0xFF10B981),
            const Color(0xFF3B82F6),
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
            const Color(0xFF8B5CF6),
            Colors.white,
          ][random.nextInt(6)],
          rotation: random.nextDouble() * 360,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622), // Dark premium background
      body: Stack(
        children: [
          // Confetti Layer
          ...List.generate(_confettiList.length, (index) {
            final c = _confettiList[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 2500 + (index * 30)),
              builder: (context, value, _) {
                return Positioned(
                  left: c.x * MediaQuery.of(context).size.width,
                  top: (c.y + value * 1.5) * MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle: c.rotation * value,
                    child: Container(
                      width: c.size,
                      height: c.size * 0.6,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 1 - value * 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Celebration Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF135bec),
                    size: 80,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Payment Received!",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "You've successfully completed\n${widget.jobTitle}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  ),
                ),

                const Spacer(),

                // Earnings Summary Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2233),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildEarningRow(
                        context,
                        label: "Amount Earned",
                        value: "₹${widget.amount.toStringAsFixed(2)}",
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.greenAccent,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10),
                      ),
                      _buildEarningRow(
                        context,
                        label: "Student Coins",
                        value: "+${widget.coins.toStringAsFixed(0)} C",
                        icon: Icons.monetization_on_rounded,
                        color: Colors.amber,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10),
                      ),
                      _buildEarningRow(
                        context,
                        label: "Experience Points",
                        value: "+${widget.points} XP",
                        icon: Icons.bolt_rounded,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Back to Dashboard Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(
                              isSeeker: false,
                              initialIndex: 0,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135bec),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Back to Dashboard",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Confetti {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double rotation;

  _Confetti({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
  });
}
