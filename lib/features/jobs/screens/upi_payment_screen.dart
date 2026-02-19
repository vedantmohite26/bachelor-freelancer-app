import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/features/ratings/screens/rate_helper_screen.dart';

class UPIPaymentScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final double amount;
  final String helperId;
  final String helperName;
  final String seekerId;

  const UPIPaymentScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.amount,
    required this.helperId,
    required this.helperName,
    required this.seekerId,
  });

  @override
  State<UPIPaymentScreen> createState() => _UPIPaymentScreenState();
}

class _UPIPaymentScreenState extends State<UPIPaymentScreen>
    with TickerProviderStateMixin {
  // Payment States
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _upiRefId;
  String? _error;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScaleAnimation;

  // Confetti
  final List<_Confetti> _confettiList = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final paymentService = Provider.of<PaymentService>(
        context,
        listen: false,
      );

      final result = await paymentService.simulateUPIPayment(
        jobId: widget.jobId,
        seekerId: widget.seekerId,
        helperId: widget.helperId,
        amount: widget.amount,
        jobTitle: widget.jobTitle,
        helperName: widget.helperName,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _upiRefId = result['upiRefId'] as String?;
          _generateConfetti();
        });
        _pulseController.stop();
        _successController.forward();

        // Auto-navigate after 4 seconds
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => RateHelperScreen(
                helperId: widget.helperId,
                jobId: widget.jobId,
                helperName: widget.helperName,
              ),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _generateConfetti() {
    final random = math.Random();
    _confettiList.clear();
    for (int i = 0; i < 50; i++) {
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
    if (_isSuccess) return _buildSuccessScreen();
    return _buildPaymentScreen();
  }

  Widget _buildPaymentScreen() {
    final simUpiId = '${widget.helperId.substring(0, 6)}@unnati';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "Secure Payment",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    blurRadius: 100,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Recipient Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF0F172A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar / Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.helperName.isNotEmpty
                                  ? widget.helperName[0].toUpperCase()
                                  : "U",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Paying to",
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.helperName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                simUpiId,
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Amount Display with Glow
                  Column(
                    children: [
                      Text(
                        "Total Amount",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                "₹${widget.amount.toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF10B981),
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Job Details (Simplified)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Job",
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.jobTitle,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Error Message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Swipe/Tap to Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shadowColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.4),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Processing...",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Pay Securely",
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer Security
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Encrypted & Secure Payment",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Glows
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          ...List.generate(_confettiList.length, (index) {
            final c = _confettiList[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 2000 + (index * 40)),
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
                        color: c.color.withValues(alpha: 1 - value * 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Success Content
          Center(
            child: ScaleTransition(
              scale: _successScaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Green checkmark
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Payment Successful!",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "₹${widget.amount.toStringAsFixed(0)} sent to ${widget.helperName}",
                    style: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Transaction Details Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Status", "SUCCESS", isGreen: true),
                        const Divider(color: Color(0xFF334155), height: 32),
                        _buildDetailRow("UPI Ref", _upiRefId ?? "N/A"),
                        const Divider(color: Color(0xFF334155), height: 32),
                        _buildDetailRow(
                          "Amount",
                          "₹${widget.amount.toStringAsFixed(0)}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Auto redirect hint
                  Text(
                    "Redirecting you shortly...",
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: isGreen ? const Color(0xFF10B981) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
