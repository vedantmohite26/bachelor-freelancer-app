import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 24.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 300.h,
                  width: double.infinity,
                  // Placeholder for Cyclist Illustration
                  decoration: const BoxDecoration(
                    // image: DecorationImage(image: AssetImage('assets/cyclist.png'))
                  ),
                  child: Icon(
                    Icons.directions_bike,
                    size: 200.sp,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                // Floating Icons
                Container(
                  padding: EdgeInsets.all(12.w),
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
            SizedBox(height: 32.h),

            Text(
              "Finding local helpers\nnear you...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "We're connecting you with trusted\nstudents in your neighborhood.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16.sp),
            ),
            SizedBox(height: 40.h),

            // Progress Bar
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.w),
              child: LinearProgressIndicator(
                value: 0.45,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryBlue,
              ),
            ),

            const Spacer(),

            // While you wait
            Text(
              "WHILE YOU WAIT",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaitAction(Icons.coffee, "Coffee Run"),
                _buildWaitAction(Icons.menu_book, "Tutoring"),
                _buildWaitAction(Icons.shopping_bag, "Groceries"),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 60.h,
          width: 60.w,
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
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
        ),
      ],
    );
  }
}
