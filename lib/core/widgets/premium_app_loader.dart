import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumAppLoader extends StatefulWidget {
  final String statusMessage;
  const PremiumAppLoader({super.key, this.statusMessage = "Loading..."});

  @override
  State<PremiumAppLoader> createState() => _PremiumAppLoaderState();
}

class _PremiumAppLoaderState extends State<PremiumAppLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    surfaceColor,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Center Content: Pulsing Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow Ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 140 + (20 * _pulseAnimation.value),
                          height: 140 + (20 * _pulseAnimation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(
                              alpha: 0.1 * (1 - _pulseAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner Pulse
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20 + (10 * _pulseAnimation.value),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Logo Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  "U",
                                  style: GoogleFonts.splineSans(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // App Name
                Text(
                  "UNNATI",
                  style: GoogleFonts.splineSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  "FREELANCER",
                  style: GoogleFonts.splineSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 40),

                // Status Message pulsing
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.6 + (0.4 * _pulseAnimation.value),
                      child: child,
                    );
                  },
                  child: Text(
                    widget.statusMessage,
                    style: GoogleFonts.splineSans(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
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
}
