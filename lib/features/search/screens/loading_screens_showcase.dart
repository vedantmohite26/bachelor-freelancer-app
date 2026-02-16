import 'package:flutter/material.dart';
import 'package:freelancer/features/search/screens/seeker_finding_helpers_screen.dart';
import 'package:freelancer/features/search/screens/helper_scanning_gigs_screen.dart';

class LoadingScreensShowcase extends StatelessWidget {
  const LoadingScreensShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loading Screens Showcase")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SeekerFindingHelpersScreen(),
                  ),
                );
              },
              child: const Text("Seeker: Finding Helpers"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HelperScanningGigsScreen(),
                  ),
                );
              },
              child: const Text("Helper: Scanning Gigs"),
            ),
          ],
        ),
      ),
    );
  }
}
