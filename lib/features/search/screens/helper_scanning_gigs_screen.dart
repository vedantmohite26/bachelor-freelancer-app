import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelperScanningGigsScreen extends StatefulWidget {
  const HelperScanningGigsScreen({super.key});

  @override
  State<HelperScanningGigsScreen> createState() =>
      _HelperScanningGigsScreenState();
}

class _HelperScanningGigsScreenState extends State<HelperScanningGigsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Create a curved animation for the pulse effect
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const primaryColor = Color(0xFF135bec);
    const backgroundDark = Color(0xFF101622);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          // 1. Background Map Layer
          Positioned.fill(
            child: Opacity(
              opacity: 0.6, // Matching CSS opacity
              child: Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCfPC67zM3hMs4qAmcfFdtth5Ykw6D9vXlsa_lGFkFdMZngWrqFaDtRdRs7vmPh7uqe2_ecg1h_J8JuQRNj0J4ftQKZ3CuZjsGPU417u-BZZ4SqAmIgCqdboWDnVlxf7j6uejM1o8hZC3sQfMM9Nxd9NOFvtU5E19AeEvvqsm4GHtNJdkJUx756RohhEqvdOniAnedH2-JRNRVpuY7BHDrFKgaX7iu-gcilyvTrzVQ-nz8lUvXyMu8N5a97riQ1pp9zopT9uaJSEfs",
                fit: BoxFit.cover,
                color: Colors.black.withValues(
                  alpha: 0.2,
                ), // Grayscale/darken effect
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundDark.withValues(alpha: 0.3),
                    backgroundDark.withValues(alpha: 0.6),
                    backgroundDark,
                  ],
                ),
              ),
            ),
          ),

          // 2. Static "Pings" (Simulating active jobs appearing)
          // Ping 1
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.15,
            child: _buildPing(primaryColor, delay: 0),
          ),
          // Ping 2
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: MediaQuery.of(context).size.width * 0.2,
            child: _buildPing(primaryColor, delay: 1),
          ),
          // Ping 3
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.3,
            child: _buildPing(primaryColor, delay: 2),
          ),

          // 3. Center Content: Pulsing Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow Ring
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    // Animated inner pulse
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 96 + (10 * _pulseAnimation.value),
                          height: 96 + (10 * _pulseAnimation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(
                              alpha: 0.4 * (1 - _pulseAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),
                    // Logo Container
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: backgroundDark.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "S",
                          style: GoogleFonts.splineSans(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Text pulsing
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity:
                          0.5 +
                          (0.5 * _pulseAnimation.value), // Fade in and out
                      child: child,
                    );
                  },
                  child: Text(
                    "Scanning nearby campus gigs...",
                    style: GoogleFonts.splineSans(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Section: Progress & Tips
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Searching area",
                              style: GoogleFonts.splineSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "45%",
                              style: GoogleFonts.splineSans(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9999),
                          child: LinearProgressIndicator(
                            value: 0.45,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            color: primaryColor,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tips Carousel
                SizedBox(
                  height: 100, // Approximate height for the card
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildTipCard(
                        icon: Icons.verified,
                        title: "Tip: Verified helpers get hired 3x faster!",
                        subtitle: "Complete your profile to get the badge.",
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(width: 16),
                      _buildTipCard(
                        icon: Icons.security,
                        title:
                            "Safety first: Always communicate through the app.",
                        subtitle:
                            "Our secure chat keeps your personal number private.",
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back button (Optional, but good for navigation safety)
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.splineSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.splineSans(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build pulsing dots
  Widget _buildPing(Color color, {required int delay}) {
    // Simple implementation of a ping animation
    // Ideally we would use separate animation controllers or a staggered animation
    // For now, static representation as per request for "Simulating"
    // Or we can add a local Pulse widget
    return _PulsingDot(color: color);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: widget.color, blurRadius: 10)],
              ),
            ),
            Container(
              width: 30 * _controller.value,
              height: 30 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.3 * (1 - _controller.value),
                ),
              ),
            ),
          ],
        );
      },
      child: const SizedBox(),
    );
  }
}
