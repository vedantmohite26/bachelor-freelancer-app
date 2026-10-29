import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';

void main() {
  group('LeaderboardService', () {
    late LeaderboardService leaderboardService;

    setUp(() {
      leaderboardService = LeaderboardService();
    });

    test('getUserBadges returns empty list for user with minimal activity', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 5,
        'rating': 4.0,
        'reviewCount': 2,
      });

      expect(badges, isEmpty);
    });

    test('getUserBadges returns Veteran badge when gigsCompleted >= 50', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 50,
        'rating': 4.5,
        'reviewCount': 5,
      });

      expect(badges, contains('Veteran'));
      expect(badges, isNot(contains('Legend')));
    });

    test('getUserBadges returns Veteran and Legend badges when gigsCompleted >= 100', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 100,
        'rating': 4.5,
        'reviewCount': 5,
      });

      expect(badges, contains('Veteran'));
      expect(badges, contains('Legend'));
    });

    test('getUserBadges returns Top Rated badge when rating >= 4.8 and reviewCount >= 10', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 20,
        'rating': 4.9,
        'reviewCount': 12,
      });

      expect(badges, contains('Top Rated'));
    });

    test('getUserBadges returns Perfect badge when rating == 5.0 and reviewCount >= 5', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 10,
        'rating': 5.0,
        'reviewCount': 6,
      });

      expect(badges, contains('Perfect'));
    });

    test('getUserBadges returns all applicable badges', () {
      final badges = leaderboardService.getUserBadges({
        'gigsCompleted': 120,
        'rating': 5.0,
        'reviewCount': 15,
      });

      expect(badges, containsAll(['Veteran', 'Legend', 'Top Rated', 'Perfect']));
    });
  });
}
