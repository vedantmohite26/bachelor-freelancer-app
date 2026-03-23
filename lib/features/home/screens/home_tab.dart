import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school,
                color: AppTheme.primaryBlue,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Location",
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
                Row(
                  children: [
                    Text(
                      "UC Berkeley Campus",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16.sp,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon!'),
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
          const CachedNetworkAvatar(radius: 18, backgroundColor: Colors.orange),
          SizedBox(width: 16.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "What do you need",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                "help with today?",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                  height: 1.1,
                ),
              ),

              SizedBox(height: 24.h),

              // Search Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                height: 50.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    SizedBox(width: 12.w),
                    Text(
                      "Search for tutors, cleaners...",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: AppTheme.primaryBlue,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Popular Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Popular Tasks",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View all tasks feature coming soon!'),
                        ),
                      );
                    },
                    child: const Text("See All"),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _CategoryCard(
                    icon: Icons.cleaning_services,
                    label: "Cleaning",
                    color: Colors.purple.shade50,
                    iconColor: Colors.purple,
                  ),
                  _CategoryCard(
                    icon: Icons.computer,
                    label: "Tech Support",
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue,
                  ),
                  _CategoryCard(
                    icon: Icons.local_shipping,
                    label: "Delivery",
                    color: Colors.orange.shade50,
                    iconColor: Colors.orange,
                  ),
                  _CategoryCard(
                    icon: Icons.menu_book,
                    label: "Tutor",
                    color: Colors.green.shade50,
                    iconColor: Colors.green,
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Nearby Helpers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Nearby Helpers",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                  ),
                  Icon(Icons.filter_list, size: 20.sp),
                ],
              ),
              SizedBox(height: 16.h),

              SizedBox(
                height: 140.h, // Height for helper cards
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'helper')
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final helpers = snapshot.data!.docs;
                    if (helpers.isEmpty) {
                      return const Text("No helpers nearby.");
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: helpers.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 12.w),
                      itemBuilder: (context, index) {
                        final helper =
                            helpers[index].data() as Map<String, dynamic>;
                        return _HelperCard(
                          name: helper['name'] ?? 'Student',
                          tagline: helper['tagline'] ?? 'General Helper',
                          rating: (helper['rating'] as num?)?.toDouble() ?? 5.0,
                          reviews: helper['reviews'] ?? 0,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Width calc for 2 columns
    final width = (MediaQuery.of(context).size.width - 48) / 2;

    return Container(
      width: width,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(width: 12.w),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  final String name;
  final String tagline;
  final double rating;
  final int reviews;

  const _HelperCard({
    required this.name,
    required this.tagline,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CachedNetworkAvatar(
            radius: 24,
            backgroundColor: Colors.teal.shade100,
            fallbackText: name,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Icon(
                      Icons.favorite_border,
                      size: 18.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  tagline,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.verified, size: 14.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      "Verified",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, size: 14.sp, color: Colors.amber),
                    Text(
                      " $rating ($reviews)",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
