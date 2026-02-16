import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/features/profile/screens/edit_profile_screen.dart';
import 'package:freelancer/features/community/screens/friend_requests_screen.dart';
import 'package:freelancer/features/search/screens/helper_scanning_gigs_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HelperProfileScreen extends StatelessWidget {
  final String helperId;
  final bool bypassPrivacy;

  const HelperProfileScreen({
    super.key,
    required this.helperId,
    this.bypassPrivacy = false,
  });

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings coming soon!")),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: userService.getUserProfileStream(helperId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Unable to load profile'));
          }

          final helper = snapshot.data!;
          final isMe = authService.user?.uid == helperId;

          final safetySettings =
              helper['safetySettings'] as Map<String, dynamic>?;
          final isProfileVisible = safetySettings?['profileVisibility'] ?? true;

          // Privacy Check
          if (!isProfileVisible && !bypassPrivacy && !isMe) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "This profile is private",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "The user has restricted visibility to\nhired students only.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final name = helper['name'] ?? 'Unknown';
          final bio = helper['bio'] ?? 'Verified Student @ State University';
          final profilePic = helper['profilePic'];
          final isOnline = helper['isOnline'] ?? false;
          final walletBalance = (helper['walletBalance'] ?? 0.0).toDouble();
          final gigsCompleted = helper['gigsCompleted'] ?? 0;
          final skills =
              (helper['skills'] as List?)?.map((s) => s.toString()).toList() ??
              [];
          final reviewCount = helper['reviewCount'] ?? 0;
          final rating = (helper['rating'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Profile Avatar & Info
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CachedNetworkAvatar(
                      imageUrl: profilePic,
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      fallbackIconColor: Colors.grey[400],
                    ),
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ],
                ),
                if (authService.user?.uid == helperId)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "My QR Code",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                QrImageView(
                                  data: helperId,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Show this to the Seeker to start the job",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text("Show QR Code"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      bio,
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (helper['university'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          helper['university'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                if (helper['phoneNumber'] != null &&
                    authService.user?.uid == helperId)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        helper['phoneNumber'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // 2. Action Buttons
                if (authService.user?.uid == helperId)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Edit Profile"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Public View Logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Public View"),
                        ),
                      ),
                    ],
                  )
                else
                  Consumer<FriendService>(
                    builder: (context, friendService, _) {
                      return StreamBuilder<FriendStatus>(
                        stream: friendService.getFriendStatusStream(
                          authService.user?.uid ?? '',
                          helperId,
                        ),
                        builder: (context, snapshot) {
                          final status = snapshot.data ?? FriendStatus.none;

                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final currentUser = authService.user;
                                    if (currentUser == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please login to message",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Handle Connection Status
                                    if (status == FriendStatus.none) {
                                      await friendService.sendFriendRequest(
                                        currentUser.uid,
                                        helperId,
                                      );
                                    } else if (status ==
                                        FriendStatus.pendingSent) {
                                      await friendService.cancelFriendRequest(
                                        currentUser.uid,
                                        helperId,
                                      );
                                    } else if (status ==
                                        FriendStatus.pendingReceived) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FriendRequestsScreen(),
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Check connection requests to respond",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        status == FriendStatus.connected
                                        ? Colors.green
                                        : (status == FriendStatus.pendingSent
                                              ? Colors.grey
                                              : AppTheme.primaryBlue),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(_getConnectionButtonText(status)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Only show Message button if connected
                              if (status == FriendStatus.connected)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final chatService =
                                          Provider.of<ChatService>(
                                            context,
                                            listen: false,
                                          );
                                      final currentUser = authService.user;

                                      if (currentUser == null) return;

                                      try {
                                        final chatId = await chatService
                                            .createChat(
                                              helperId,
                                              currentUser.uid,
                                            );
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                chatId: chatId,
                                                otherUserName: name,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Error: ${e.toString()}",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryBlue,
                                      side: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("Message"),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // 3. Online Status Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi,
                          color: isOnline
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? "You are Online" : "You are Offline",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isOnline
                                ? "Receiving new gig offers"
                                : "Not receiving gigs",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Switch(
                        value: isOnline,
                        onChanged: (value) async {
                          if (value) {
                            // Show scanning animation when going online
                            bool scanning = true;

                            // Start timer to auto-close screen after delay
                            Future.delayed(const Duration(seconds: 3), () {
                              if (scanning && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            });

                            // Wait for screen to close (either by timer or user back)
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const HelperScanningGigsScreen(),
                              ),
                            );

                            scanning = false;
                          }

                          await userService.updateOnlineStatus(helperId, value);
                        },
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Earnings
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Earnings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TOTAL EARNINGS",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${walletBalance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "+₹50.00 this week",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$gigsCompleted",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Gigs Completed",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gig history feature coming soon!',
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text("View History"),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. My Skills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My Skills",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                      child: const Text("Edit"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...skills.map((skill) => _SkillChip(label: skill)),
                    // Add Button Placeholder
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. Reviews
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "/ 5.0",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Based on $reviewCount reviews",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mock Progress Bars (Visual only for now)
                      _buildRatingBar(5, 0.75),
                      _buildRatingBar(4, 0.15),
                      _buildRatingBar(3, 0.05),
                      _buildRatingBar(2, 0.05),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // View all reviews
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Read all reviews"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getConnectionButtonText(FriendStatus status) {
    switch (status) {
      case FriendStatus.pendingSent:
        return "Requested";
      case FriendStatus.pendingReceived:
        return "Respond";
      case FriendStatus.connected:
        return "Connected";
      case FriendStatus.none:
        return "Connect";
    }
  }

  Widget _buildRatingBar(int star, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$star", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey[100],
                color: AppTheme.primaryBlue,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${(pct * 100).toInt()}%",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mock Icons for variety
          if (label.toLowerCase().contains('dog'))
            const Icon(Icons.pets, size: 16, color: Colors.brown)
          else if (label.toLowerCase().contains('clean'))
            const Icon(Icons.cleaning_services, size: 16, color: Colors.orange)
          else
            const Icon(Icons.star, size: 16, color: Colors.blue),

          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
