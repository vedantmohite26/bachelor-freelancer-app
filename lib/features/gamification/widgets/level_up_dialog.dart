import 'package:flutter/material.dart';

class LevelUpDialog extends StatelessWidget {
  const LevelUpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1C), // Deep brownish/black
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "PROMOTION UNLOCKED",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ).createShader(bounds),
              child: const Text(
                "LEVEL 6",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  height: 4,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Mock Image Placeholder for Gold Chest
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                // color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons
                    .redeem_rounded, // Best fit for "Treasure Chest" in default icons
                size: 100,
                color: Colors.amber,
              ),
              // In real app, use: Image.asset('assets/chest.png')
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D1E),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "BONUS REWARD",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "+500 Coins Earned!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Great job completing the\nweekly challenge gig.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Balance Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.currency_bitcoin,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "TOTAL BALANCE",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      Text(
                        "2,450",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shopping_bag_outlined),
                    SizedBox(width: 8),
                    Text(
                      "Spend in Coin Shop",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
