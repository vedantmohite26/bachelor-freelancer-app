import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class ProfileViewScreen extends StatelessWidget {
  final bool isHelper;
  const ProfileViewScreen({super.key, this.isHelper = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Student Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon!')),
              );
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Profile Header
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CachedNetworkAvatar(
                  imageUrl: 'https://i.pravatar.cc/300?img=11',
                  radius: 50,
                  backgroundColor: Colors.amber,
                ),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              "Alex Rivera",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Computer Science Major • 4.8",
                  style: TextStyle(color: Colors.grey),
                ),
                Icon(Icons.star, color: Colors.grey, size: 14.sp),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              "Versatile helper skilled in coding and moving.\nAlways happy to help fellow students!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Messaging feature coming soon!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.w),
                      ),
                    ),
                    child: const Text("Message"),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Already friends!')),
                      );
                    },
                    icon: Icon(Icons.check, size: 16.sp),
                    label: const Text("Friends"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                        color: Color(0xFF2C3E50),
                      ), // Darker border
                      backgroundColor: const Color(0xFF1F1F2E),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.w),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Skills Chips
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSkillChip(Icons.code, "Coding"),
                  SizedBox(width: 8.w),
                  _buildSkillChip(Icons.local_shipping, "Moving"),
                  SizedBox(width: 8.w),
                  _buildSkillChip(Icons.school, "Tutoring"),
                  SizedBox(width: 8.w),
                  _buildSkillChip(Icons.pets, "Dog Walking"),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Mutual Friends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mutual Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View all mutual friends coming soon!'),
                      ),
                    );
                  },
                  child: const Text(
                    "View all (12)",
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 90.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFriendAvatar("Sarah", Colors.orange),
                  _buildFriendAvatar("Mike", Colors.teal),
                  _buildFriendAvatar("Jessica", Colors.purple),
                  _buildFriendAvatar("David", Colors.brown),
                  _buildFriendAvatar("Emma", Colors.pink),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Community Kudos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Community Kudos",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add kudos feature coming soon!'),
                      ),
                    );
                  },
                  child: const Text(
                    "+ Add Kudos",
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
            _buildKudoCard(
              name: "Anna Chen",
              time: "2 days ago",
              tag: "Helpful",
              tagColor: Colors.amber,
              description:
                  "Alex was super helpful with my Java assignment. Explained everything clearly and didn't just give me the answers!",
            ),
            SizedBox(height: 16.h),
            _buildKudoCard(
              name: "Tom Wilson",
              time: "1 week ago",
              tag: "Friendly",
              tagColor: Colors.purpleAccent,
              description:
                  "Helped me move a couch up three flights of stairs. A lifesaver!",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(20.w),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16.sp),
          SizedBox(width: 6.w),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFriendAvatar(String name, Color color) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(name[0], style: const TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 8.h),
          Text(name, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildKudoCard({
    required String name,
    required String time,
    required String tag,
    required Color tagColor,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey,
                child: Text(
                  name[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 12.sp, color: tagColor),
                    SizedBox(width: 4.w),
                    Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(description, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
