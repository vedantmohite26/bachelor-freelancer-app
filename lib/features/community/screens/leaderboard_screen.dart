import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          "Leaderboard",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<LeaderboardService>(
          context,
          listen: false,
        ).getLeaderboard(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final leaderboard = snapshot.data ?? [];
          final authService = Provider.of<AuthService>(context, listen: false);
          final currentUserId = authService.user?.uid ?? '';

          // Find current user rank
          final currentUserIndex = leaderboard.indexWhere(
            (user) => user['id'] == currentUserId,
          );
          final currentUserRank = currentUserIndex >= 0
              ? currentUserIndex + 1
              : 0;
          final currentUserData = currentUserIndex >= 0
              ? leaderboard[currentUserIndex]
              : null;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Your Rank Card
                if (currentUserData != null)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Your Rank",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "#",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$currentUserRank",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "${currentUserData['points']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Points",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFBBF24),
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(currentUserData['badges'] as List?)?.length ?? 0} Badges",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Top 3
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Top Performers",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                if (leaderboard.length >= 3)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // #2
                      _PodiumCard(
                        rank: 2,
                        name: leaderboard[1]['name'] ?? 'User',
                        points: "${leaderboard[1]['points']}",
                        avatar: null,
                        height: 140,
                        color: const Color(0xFFC0C0C0),
                      ),

                      const SizedBox(width: 16),

                      // #1
                      _PodiumCard(
                        rank: 1,
                        name: leaderboard[0]['name'] ?? 'User',
                        points: "${leaderboard[0]['points']}",
                        avatar: null,
                        height: 180,
                        color: const Color(0xFFFBBF24),
                      ),

                      const SizedBox(width: 16),

                      // #3
                      _PodiumCard(
                        rank: 3,
                        name: leaderboard[2]['name'] ?? 'User',
                        points: "${leaderboard[2]['points']}",
                        avatar: null,
                        height: 120,
                        color: const Color(0xFFCD7F32),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Rest of Rankings
                Container(
                  color: colorScheme.surfaceContainerLowest,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leaderboard.length > 3
                        ? leaderboard.length - 3
                        : 0,
                    padding: const EdgeInsets.all(20),
                    itemBuilder: (context, index) {
                      final userIndex = index + 3;
                      final user = leaderboard[userIndex];
                      return _RankingCard(
                        rank: userIndex + 1,
                        name: user['name'] ?? 'User',
                        points: "${user['points']}",
                        isCurrentUser: user['id'] == currentUserId,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final String name;
  final String points;
  final String? avatar;
  final double height;
  final Color color;

  const _PodiumCard({
    required this.rank,
    required this.name,
    required this.points,
    this.avatar,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            CachedNetworkAvatar(
              radius: rank == 1 ? 40 : 32,
              backgroundColor: Colors.grey.shade200,
              fallbackText: name,
            ),
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: rank == 1 ? 20 : 16,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          name,
          style: TextStyle(
            fontSize: rank == 1 ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "$points pts",
          style: TextStyle(fontSize: rank == 1 ? 14 : 12, color: Colors.grey),
        ),

        const SizedBox(height: 12),

        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "#$rank",
                style: TextStyle(
                  fontSize: rank == 1 ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final String name;
  final String points;
  final bool isCurrentUser;

  const _RankingCard({
    required this.rank,
    required this.name,
    required this.points,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppTheme.primaryBlue : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppTheme.primaryBlue
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Avatar
          CachedNetworkAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            fallbackText: name,
          ),

          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$points pts",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "YOU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
