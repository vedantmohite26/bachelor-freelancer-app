import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SeekerFindingHelpersScreen extends StatefulWidget {
  const SeekerFindingHelpersScreen({super.key});

  @override
  State<SeekerFindingHelpersScreen> createState() =>
      _SeekerFindingHelpersScreenState();
}

class _SeekerFindingHelpersScreenState extends State<SeekerFindingHelpersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const primaryColor = Color(0xFF2b8cee);
    const backgroundColorLight = Color(0xFFf6f7f8);
    // final backgroundColorDark = const Color(0xFF101922); // For dark mode support later

    return Scaffold(
      backgroundColor: backgroundColorLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          "Search in progress",
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Central Illustration Area
                      SizedBox(
                        height: 300,
                        width: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Main Image
                            Container(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "https://lh3.googleusercontent.com/aida-public/AB6AXuAhu_Vfo8RpNzyXqZAKBb-xBYW8ybIll9gz_wJ3o2nLZcot8BtuAQghWsma31scR5BGd9mkObZggfKimD0iRhbz08cniZaJ-EstAIqs2SHJU-quBBxl4OHd3bTErbbvwjLLoe7ZECfelWNG43aNAImKB6mxm9AWAbt14YlFZdWHOPGOMm3Qdjpdwh4MduVE3E4SO_v-m1FPzESDsAczfvD9pW5N6ksqu2zmfsjBF-fgBHek_EkfeFlumivWSGdddWPUJ6AcGFx-xvA",
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Floating Icon 1 (Mop) - Animated
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Positioned(
                                  top:
                                      10 +
                                      (_animation.value * 10), // Bounce effect
                                  right: 40,
                                  child: child!,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.cleaning_services,
                                  color: primaryColor,
                                  size: 30,
                                ),
                              ),
                            ),
                            // Floating Icon 2 (Laptop) - Static/Low Opacity
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.laptop_mac,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Headline Text
                      Text(
                        "Finding local helpers near you...",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF111418),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We're connecting you with trusted students in your neighborhood.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF637588),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Progress Bar
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Searching...",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF111418),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "45%",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF637588),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9999),
                              child: const LinearProgressIndicator(
                                value: 0.45,
                                backgroundColor: Color(0xFFdbe0e6),
                                color: primaryColor,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom "While you wait" section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "WHILE YOU WAIT",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111418).withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      _QuickCategory(
                        icon: Icons.local_cafe,
                        label: "Coffee Run",
                        primaryColor: primaryColor,
                      ),
                      SizedBox(width: 12),
                      _QuickCategory(
                        icon: Icons.menu_book,
                        label: "Tutoring",
                        primaryColor: primaryColor,
                      ),
                      SizedBox(width: 12),
                      _QuickCategory(
                        icon: Icons.shopping_bag,
                        label: "Groceries",
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;

  const _QuickCategory({
    required this.icon,
    required this.label,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF111418),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
