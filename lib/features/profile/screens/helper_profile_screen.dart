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
import 'package:freelancer/features/ratings/screens/helper_reviews_screen.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/features/jobs/screens/helper_completed_jobs_screen.dart';
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
    final ratingService = Provider.of<RatingService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          authService.user?.uid == helperId ? "My Profile" : "Helper Profile",
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
          if (authService.user?.uid == helperId)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
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
          final profilePic = helper['photoUrl'];
          final isOnline = helper['isOnline'] ?? false;
          final walletBalance = (helper['walletBalance'] ?? 0.0).toDouble();
          final gigsCompleted = helper['gigsCompleted'] ?? 0;
          final skills =
              (helper['skills'] as List?)?.map((s) => s.toString()).toList() ??
              [];
          final skillCertificates =
              (helper['skillCertificates'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, value.toString()),
              ) ??
              <String, String>{};

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
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 3,
                        ),
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
                            backgroundColor: colorScheme.surface,
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
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                            backgroundColor: colorScheme.surfaceContainerLow,
                            foregroundColor: colorScheme.onSurface,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Public Profile View coming soon!',
                                ),
                              ),
                            );
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
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            isOnline
                                ? "Receiving new gig offers"
                                : "Not receiving gigs",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
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

                if (isMe) ...[
                  // 4. Earnings
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Earnings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL EARNINGS",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${walletBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
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
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Gigs Completed",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HelperCompletedJobsScreen(),
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
                ],

                // 5. My Skills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMe ? "My Skills" : "Skills",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isMe)
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
                    ...skills.map(
                      (skill) => _SkillChip(
                        label: skill,
                        certificateUrl: skillCertificates[skill],
                      ),
                    ),
                    // Add Button Placeholder (only for own profile)
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Icon(
                          Icons.add,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. Reviews
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: ratingService.getHelperRatings(helperId),
                    builder: (context, ratingsSnapshot) {
                      final reviews = ratingsSnapshot.data ?? [];
                      final count = reviews.length;
                      final avg = count > 0
                          ? reviews
                                    .map(
                                      (r) => (r['overallRating'] as num)
                                          .toDouble(),
                                    )
                                    .reduce((a, b) => a + b) /
                                count
                          : 0.0;

                      // Calculate distribution
                      final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
                      for (var r in reviews) {
                        final star = (r['overallRating'] as num).toInt();
                        if (distribution.containsKey(star)) {
                          distribution[star] = (distribution[star] ?? 0) + 1;
                        }
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                avg.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "/ 5.0",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < avg.round()
                                        ? Icons.star
                                        : Icons.star_border,
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
                              "Based on $count reviews",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dynamic Progress Bars
                          ...[5, 4, 3, 2, 1].map((star) {
                            final starCount = distribution[star] ?? 0;
                            final pct = count > 0 ? starCount / count : 0.0;
                            return _buildRatingBar(context, star, pct);
                          }),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HelperReviewsScreen(
                                      helperId: helperId,
                                      averageRating: avg,
                                      reviewCount: count,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                backgroundColor:
                                    colorScheme.surfaceContainerLow,
                                foregroundColor: colorScheme.onSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Read all reviews"),
                            ),
                          ),
                        ],
                      );
                    },
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

  Widget _buildRatingBar(BuildContext context, int star, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$star",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                color: AppTheme.primaryBlue,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${(pct * 100).toInt()}%",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final String? certificateUrl;
  const _SkillChip({required this.label, this.certificateUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCertificate = certificateUrl != null && certificateUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasCertificate ? () => _showCertificate(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasCertificate
              ? Colors.green.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasCertificate
                ? Colors.green.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCertificate)
              const Icon(Icons.verified, size: 16, color: Colors.green)
            else if (label.toLowerCase().contains('dog'))
              const Icon(Icons.pets, size: 16, color: Colors.brown)
            else if (label.toLowerCase().contains('clean'))
              const Icon(
                Icons.cleaning_services,
                size: 16,
                color: Colors.orange,
              )
            else
              Icon(Icons.star, size: 16, color: colorScheme.primary),

            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificate(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$label Certificate",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  child: Image.network(
                    certificateUrl!,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Failed to load certificate",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
