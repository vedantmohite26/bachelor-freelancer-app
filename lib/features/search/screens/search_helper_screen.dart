import 'package:flutter/material.dart';
import 'package:freelancer/core/theme/app_theme.dart';

class SearchHelperScreen extends StatelessWidget {
  const SearchHelperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light theme per design
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Search in progress",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  // Placeholder for Cyclist Illustration
                  decoration: const BoxDecoration(
                    // image: DecorationImage(image: AssetImage('assets/cyclist.png'))
                  ),
                  child: const Icon(
                    Icons.directions_bike,
                    size: 200,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                // Floating Icons
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cleaning_services,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              "Finding local helpers\nnear you...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We're connecting you with trusted\nstudents in your neighborhood.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Searching...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "45%",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.45,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryBlue,
              ),
            ),

            const Spacer(),

            // While you wait
            const Text(
              "WHILE YOU WAIT",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaitAction(Icons.coffee, "Coffee Run"),
                _buildWaitAction(Icons.menu_book, "Tutoring"),
                _buildWaitAction(Icons.shopping_bag, "Groceries"),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
