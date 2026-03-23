import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/rewards_service.dart';
import 'package:freelancer/features/wallet/screens/purchase_success_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CoinShopScreen extends StatefulWidget {
  const CoinShopScreen({super.key});

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  late Stream<List<Map<String, dynamic>>> _redeemCodesStream;
  late Stream<List<Map<String, dynamic>>> _powerUpsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // FIX: Initialize streams once to prevent redundant API calls on every rebuild
    final rewardsService = Provider.of<RewardsService>(context, listen: false);
    _redeemCodesStream = rewardsService.getRewards('redeem_code');
    _powerUpsStream = rewardsService.getRewards('power_up');

    // Ensure wallet listener is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user != null) {
        Provider.of<WalletService>(
          context,
          listen: false,
        ).listenToWallet(authService.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem(Map<String, dynamic> item) async {
    final walletService = Provider.of<WalletService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    final String title = item['title'] ?? '';
    final int cost = item['cost'] ?? 0;
    final String category = item['category'] ?? '';

    if (userId == null) return;

    if (walletService.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient coins! Complete more gigs."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Deduct coins via transaction
      await walletService.addTransaction(
        userId: userId,
        title: "Purchased: $title",
        amount: -cost.toDouble(),
        isCoin: true,
        type: 'shop_purchase',
        category: 'Freelance',
        isAppGenerated: true,
      );

      // 2. Activate Power-Up if applicable
      if (category == 'power_up') {
        Duration duration = const Duration(hours: 24); // Default
        if (title.contains('Highlight')) {
          duration = const Duration(days: 3); // Highlight lasts 3 days
        }

        await walletService.activatePowerUp(userId, title, duration);
      }

      if (!mounted) return;

      // 3. Success Navigation with full item data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(
            title: title,
            subtitle: item['subtitle'] ?? '',
            cost: cost,
            category: category,
            color: item['color'] ?? 0xFFFFFFFF,
            iconName: item['icon'] ?? 'card_giftcard',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Earnify Shop",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Debug Seed Button
          IconButton(
            icon: Icon(
              Icons.cloud_upload,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20.sp,
            ),
            onPressed: () async {
              await Provider.of<RewardsService>(
                context,
                listen: false,
              ).seedRewards();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Seeded Shop Rewards!")),
                );
              }
            },
            tooltip: "Debug: Seed Rewards",
          ),
          // Debug Add Coins Button
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.greenAccent,
              size: 20.sp,
            ),
            onPressed: () async {
              final walletService = Provider.of<WalletService>(
                context,
                listen: false,
              );
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              if (authService.user?.uid != null) {
                await walletService.addTransaction(
                  userId: authService.user!.uid,
                  title: "Debug: Added Coins",
                  amount: 5000,
                  isCoin: true,
                  type: 'debug_add',
                  category: 'Freelance',
                  isAppGenerated: true,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added 5000 Coins!")),
                  );
                }
              }
            },
            tooltip: "Debug: Add 5000 Coins",
          ),
        ],
      ),
      body: Column(
        children: [
          // Prominent Balance Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            child: Column(
              children: [
                Text(
                  "YOUR BALANCE",
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Consumer<WalletService>(
                  builder: (context, wallet, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: theme.colorScheme.tertiary,
                          size: 32.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          "${wallet.coins}",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 48.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "COINS",
                          style: TextStyle(
                            color: theme.colorScheme.tertiary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Custom TabBar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            height: 48.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12.w),
                color: const Color.fromARGB(255, 255, 255, 0),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: theme.colorScheme.onSurface,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Text(
                    "Redeem Codes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Tab(
                  child: Text(
                    "Power-ups",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRewardsGrid('redeem_code', 1.2),
                      _buildRewardsGrid('power_up', 0.65),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsGrid(String category, double aspectRatio) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: category == 'redeem_code' ? _redeemCodesStream : _powerUpsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  "No items available in $category",
                  style: const TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Tip: Tap the cloud icon ☁️ to seed data!",
                  style: TextStyle(color: Colors.white24, fontSize: 12.sp),
                ),
              ],
            ),
          );
        }

        if (category == 'redeem_code') {
          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: rewards.length,
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: _buildRedeemCodeCard(rewards[index]),
              );
            },
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            return RepaintBoundary(child: _buildPowerUpCard(rewards[index]));
          },
        );
      },
    );
  }

  Widget _buildRedeemCodeCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    // Parse color
    final Color brandColor = Color(item['color'] ?? 0xFFFFFFFF);
    final IconData icon = _getIconData(item['icon'] ?? 'card_giftcard');

    return GestureDetector(
      onTap: () => _handleRedeem(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.w),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandColor, brandColor.withValues(alpha: 0.6)],
          ),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern (Circles)
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                icon,
                size: 100.sp,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Icon
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 16.sp),
                      ),
                      // "GIFT CARD" Label
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        child: Text(
                          "GIFT CARD",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Value and Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? '',
                        style: TextStyle(
                          color: brandColor.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          shadows: [
                            Shadow(
                              color: brandColor.computeLuminance() > 0.5
                                  ? Colors.white24
                                  : Colors.black45,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['subtitle'] ?? '',
                        style: TextStyle(
                          color: brandColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),

                  // Price Button (Bottom)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: theme.colorScheme.tertiary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          item['cost'].toString(),
                          style: TextStyle(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUpCard(Map<String, dynamic> item) {
    final IconData icon = _getIconData(item['icon'] ?? 'help');
    final Color color = Color(item['color'] ?? 0xFFFFFFFF);
    final bool isHighlight =
        item['title']?.toString().contains('Highlight') ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          if (isHighlight)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                backgroundBlendMode: BlendMode.overlay,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox(),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Bubble
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(icon, size: 32.sp, color: color),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  item['title'] ?? 'Reward',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 6.h),

                // Subtitle
                Text(
                  item['subtitle'] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Buy Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleRedeem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700), // Gold
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 0.h,
                        horizontal: 8.w,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          "${item['cost']}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'play_arrow':
        return Icons.play_arrow;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'music_note':
        return Icons.music_note;
      case 'restaurant':
        return Icons.restaurant;
      case 'ac_unit': // Streak Freeze
        return Icons.ac_unit;
      case 'lightbulb': // Hint
        return Icons.lightbulb;
      case 'bolt': // XP Boost
        return Icons.bolt;
      case 'verified':
        return Icons.verified;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'checkroom':
        return Icons.checkroom;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      default:
        return Icons.star;
    }
  }
}
