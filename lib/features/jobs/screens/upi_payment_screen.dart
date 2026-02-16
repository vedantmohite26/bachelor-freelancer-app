import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    final qrData =
        'upi://pay?pa=$simUpiId&pn=${widget.helperName}&am=${widget.amount}&tn=Job-${widget.jobId.substring(0, 6)}&cu=INR';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          "Payment",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // UPI Logo & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  // UPI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "UPI Payment",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Job Info
                  Text(
                    widget.jobTitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Paying ${widget.helperName}",
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    simUpiId,
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF3B82F6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount Display
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isProcessing
                            ? [const Color(0xFF1E293B), const Color(0xFF1E293B)]
                            : [
                                const Color(0xFF1E3A8A),
                                const Color(0xFF3B82F6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Amount",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${widget.amount.toStringAsFixed(0)}",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // QR Code (UPI-style)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 160.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scan to pay via any UPI app",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Processing...",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Pay ₹${widget.amount.toStringAsFixed(0)}",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  "Secured by Unnati Pay",
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
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
                  // Green checkmark circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Payment Successful!",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "₹${widget.amount.toStringAsFixed(0)} paid to ${widget.helperName}",
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transaction Details Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Status", "SUCCESS", isGreen: true),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildDetailRow("UPI Ref", _upiRefId ?? "N/A"),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildDetailRow("Job", widget.jobTitle),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildDetailRow(
                          "Amount",
                          "₹${widget.amount.toStringAsFixed(0)}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Returning to home...",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 13,
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
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: isGreen ? const Color(0xFF10B981) : Colors.white,
              fontSize: 13,
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
