import 'dart:math';
import 'package:flutter/material.dart';
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
              height: 200,
              width: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                isPowerUp ? Icons.rocket_launch : Icons.celebration,
                color: brandColor,
                size: 100,
              ),
            ),

            Text(
              isPowerUp ? "Activated!" : "You got it!",
              style: GoogleFonts.outfit(
                color: colorScheme.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPowerUp
                  ? "${widget.title} is now active."
                  : "Your reward is ready. Reveal your code below.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Card Section
            if (isPowerUp)
              _buildPowerUpCard(brandColor, icon, colorScheme)
            else
              _buildRedeemCodeCard(brandColor, icon, colorScheme),

            const SizedBox(height: 32),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  const SizedBox(width: 16),
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
            const SizedBox(height: 32),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (!isPowerUp)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text(
                              "Copy Code",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isPowerUp) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text("Back to Shop"),
                    ),
                  ),
                  const SizedBox(height: 32),
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandColor, brandColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Icon
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
                // Brand Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(icon, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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
            padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isRevealed
                          ? brandColor.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(30),
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
                            size: 20,
                          ),
                        if (!_isRevealed) const SizedBox(width: 8),
                        Text(
                          _isRevealed ? _generatedCode : "Tap to reveal code",
                          style: GoogleFonts.jetBrainsMono(
                            color: _isRevealed
                                ? brandColor
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Expires in 30 days.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.4),
          width: 1.5,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.15),
              border: Border.all(
                color: brandColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: brandColor),
          ),
          const SizedBox(height: 24),

          Text(
            widget.title,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Duration Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: brandColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: brandColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Active for $duration",
                  style: TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              symbol == "+" ? Icons.add : Icons.remove,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
