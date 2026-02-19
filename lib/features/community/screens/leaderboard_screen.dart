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

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Map<String, dynamic>>> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // FIX: Initialize stream once to prevent redundant subscriptions on every rebuild
    _leaderboardStream = Provider.of<LeaderboardService>(
      context,
      listen: false,
    ).getLeaderboard(limit: 50);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Leaderboard",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Debug Button to add Demo Helpers
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: () async {
              await Provider.of<LeaderboardService>(
                context,
                listen: false,
              ).generateDemoHelpers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Added 10 Demo Helpers!")),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: "Global"),
            Tab(text: "Friends"),
            Tab(text: "This Week"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalLeaderboard(), // Top Helpers
          _buildPlaceholder("Friends Leaderboard coming soon!"),
          _buildPlaceholder("Weekly challenges coming soon!"),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _leaderboardStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaderboard = snapshot.data ?? [];
        if (leaderboard.isEmpty) {
          return _buildPlaceholder("No helpers found yet.");
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Podium (Top 3)
              if (leaderboard.isNotEmpty) _buildPodium(leaderboard),

              const SizedBox(height: 20),

              // List (Rank 4+)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  // Rounded top corners
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leaderboard.length > 3
                      ? leaderboard.length - 3
                      : 0,
                  itemBuilder: (context, index) {
                    final user = leaderboard[index + 3];
                    return RepaintBoundary(
                      child: _RankingCard(
                        rank: index + 4,
                        name: user['name'] ?? 'User',
                        points: "${user['points']} pts",
                        isCurrentUser:
                            user['id'] ==
                            Provider.of<AuthService>(
                              context,
                              listen: false,
                            ).user?.uid,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> users) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd Place (Left)
            if (users.length > 1)
              Expanded(
                child: _PodiumItem(
                  rank: 2,
                  user: users[1],
                  color: const Color(0xFFC0C0C0), // Silver
                  height: 140,
                ),
              ),

            // 1st Place (Center - Biggest)
            if (users.isNotEmpty)
              Expanded(
                flex: 1, // Slightly wider
                child: _PodiumItem(
                  rank: 1,
                  user: users[0],
                  color: const Color(0xFFFFD700), // Gold
                  height: 180,
                  isFirst: true,
                ),
              ),

            // 3rd Place (Right)
            if (users.length > 2)
              Expanded(
                child: _PodiumItem(
                  rank: 3,
                  user: users[2],
                  color: const Color(0xFFCD7F32), // Bronze
                  height: 120,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final Color color;
  final double height;
  final bool isFirst;

  const _PodiumItem({
    required this.rank,
    required this.user,
    required this.color,
    required this.height,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar with Badge
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(isFirst ? 4 : 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: CachedNetworkAvatar(
                radius: isFirst ? 40 : 30,
                fallbackText: user['name'] ?? 'U',
                backgroundColor: Colors.grey[800],
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$rank",
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          user['name'] ?? 'User',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "${user['points']} pts",
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Podium Block
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.45,
                ),
                color.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.05 : 0.15,
                ),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "#$rank",
                style: TextStyle(
                  color: color,
                  fontSize: isFirst ? 32 : 24,
                  fontWeight: FontWeight.bold,
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryBlue.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser ? Border.all(color: AppTheme.primaryBlue) : null,
      ),
      child: Row(
        children: [
          Text(
            "#$rank",
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          CachedNetworkAvatar(
            radius: 20,
            fallbackText: name,
            backgroundColor: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              color: AppTheme.growthGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
