import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Alex Rivera",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Computer Science Major • 4.8",
                  style: TextStyle(color: Colors.grey),
                ),
                Icon(Icons.star, color: Colors.grey, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Versatile helper skilled in coding and moving.\nAlways happy to help fellow students!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text("Message"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Already friends!')),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Friends"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                        color: Color(0xFF2C3E50),
                      ), // Darker border
                      backgroundColor: const Color(0xFF1F1F2E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Skills Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSkillChip(Icons.code, "Coding"),
                  const SizedBox(width: 8),
                  _buildSkillChip(Icons.local_shipping, "Moving"),
                  const SizedBox(width: 8),
                  _buildSkillChip(Icons.school, "Tutoring"),
                  const SizedBox(width: 8),
                  _buildSkillChip(Icons.pets, "Dog Walking"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mutual Friends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Mutual Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
              height: 90,
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
            const SizedBox(height: 24),

            // Community Kudos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Community Kudos",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFriendAvatar(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(name[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(16),
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
              const SizedBox(width: 12),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 12, color: tagColor),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
