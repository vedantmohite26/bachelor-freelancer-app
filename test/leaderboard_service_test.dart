import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

void main() {
  group('LeaderboardService Unit Tests', () {
    late LeaderboardService leaderboardService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      leaderboardService = LeaderboardService(firestore: fakeFirestore);
    });

    test('getUserBadges correctly evaluates user achievement badges', () {
      final veteranData = {'gigsCompleted': 50, 'rating': 4.0, 'reviewCount': 5};
      expect(leaderboardService.getUserBadges(veteranData), contains('Veteran'));

      final legendData = {'gigsCompleted': 100, 'rating': 4.0, 'reviewCount': 5};
      expect(leaderboardService.getUserBadges(legendData), containsAll(['Veteran', 'Legend']));

      final topRatedData = {'gigsCompleted': 10, 'rating': 4.9, 'reviewCount': 10};
      expect(leaderboardService.getUserBadges(topRatedData), contains('Top Rated'));

      final perfectData = {'gigsCompleted': 5, 'rating': 5.0, 'reviewCount': 5};
      expect(leaderboardService.getUserBadges(perfectData), contains('Perfect'));

      final combinedData = {'gigsCompleted': 120, 'rating': 5.0, 'reviewCount': 20};
      expect(
        leaderboardService.getUserBadges(combinedData),
        containsAll(['Veteran', 'Legend', 'Top Rated', 'Perfect']),
      );

      final noviceData = {'gigsCompleted': 5, 'rating': 4.2, 'reviewCount': 2};
      expect(leaderboardService.getUserBadges(noviceData), isEmpty);
    });
  });
}
