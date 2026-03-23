import 'dart:math';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseSuccessScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int cost;
  final String category; // 'redeem_code' or 'power_up'
  final int color;
  final String iconName;

  const PurchaseSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.category,
    required this.color,
    required this.iconName,
  });

  @override
  State<PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends State<PurchaseSuccessScreen> {
  bool _isRevealed = false;
  late String _generatedCode;

  @override
  void initState() {
    super.initState();
    _generatedCode = _generateCode();
  }

  String _generateCode() {
    final rand = Random();
    String segment() => List.generate(
      4,
      (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[rand.nextInt(36)],
    ).join();
    return '${segment()}-${segment()}-${segment()}';
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
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'checkroom':
        return Icons.checkroom;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'bolt':
        return Icons.bolt;
      case 'verified':
        return Icons.verified;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandColor = Color(widget.color);
    final icon = _getIconData(widget.iconName);
    final isPowerUp = widget.category == 'power_up';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPowerUp ? "Power-Up Activated!" : "Purchase Success",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Celebration Icon
            Container(
              height: 200.h,
              width: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                isPowerUp ? Icons.rocket_launch : Icons.celebration,
                color: brandColor,
                size: 100.sp,
              ),
            ),

            Text(
              isPowerUp ? "Activated!" : "You got it!",
              style: GoogleFonts.outfit(
                color: colorScheme.onSurface,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isPowerUp
                  ? "${widget.title} is now active."
                  : "Your reward is ready. Reveal your code below.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            // Card Section
            if (isPowerUp)
              _buildPowerUpCard(brandColor, icon, colorScheme)
            else
              _buildRedeemCodeCard(brandColor, icon, colorScheme),

            SizedBox(height: 32.h),

            // Stats Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "-",
                      "${widget.cost}",
                      "COINS SPENT",
                      Colors.redAccent,
                      colorScheme,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildStatCard(
                      "+",
                      isPowerUp ? "Active" : widget.title.split(' ').last,
                      isPowerUp ? "POWER-UP" : "VALUE GAINED",
                      Colors.green,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  if (!isPowerUp)
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _generatedCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: brandColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.w),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.copy),
                            SizedBox(width: 8.w),
                            const Text(
                              "Copy Code",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isPowerUp) SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.w),
                        ),
                      ),
                      child: const Text("Back to Shop"),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemCodeCard(
    Color brandColor,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandColor, brandColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Card Visual
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Icon
                Container(
                  height: 80.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  child: Icon(icon, color: Colors.white, size: 40.sp),
                ),
                // Brand Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(icon, color: Colors.white, size: 32.sp),
                    SizedBox(height: 8.h),
                    Text(
                      widget.title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reveal Area
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isRevealed = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: _isRevealed
                          ? brandColor.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(30.w),
                      border: Border.all(
                        color: _isRevealed
                            ? brandColor.withValues(alpha: 0.3)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isRevealed)
                          Icon(
                            Icons.touch_app,
                            color: colorScheme.onSurface,
                            size: 20.sp,
                          ),
                        if (!_isRevealed) SizedBox(width: 8.w),
                        Text(
                          _isRevealed ? _generatedCode : "Tap to reveal code",
                          style: GoogleFonts.jetBrainsMono(
                            color: _isRevealed
                                ? brandColor
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "Expires in 30 days.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpCard(
    Color brandColor,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isHighlight = widget.title.contains('Highlight');
    final duration = isHighlight ? '3 days' : '24 hours';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.4),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.15),
              border: Border.all(
                color: brandColor.withValues(alpha: 0.3),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 48.sp, color: brandColor),
          ),
          SizedBox(height: 24.h),

          Text(
            widget.title,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            widget.subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14.sp),
          ),
          SizedBox(height: 20.h),

          // Duration Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.w),
              border: Border.all(color: brandColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: brandColor, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  "Active for $duration",
                  style: TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String symbol,
    String value,
    String label,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              symbol == "+" ? Icons.add : Icons.remove,
              color: color,
              size: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
