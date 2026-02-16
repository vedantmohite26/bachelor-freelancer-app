import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RewardsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all rewards from Firestore
  Future<List<Map<String, dynamic>>> getRewards() async {
    try {
      final snapshot = await _db
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        return _defaultRewards;
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Reward',
          'subtitle': data['subtitle'] ?? '',
          'cost': data['cost'] ?? 0,
          'icon': _getIconFromName(data['icon'] ?? 'card_giftcard'),
          'color': _getColorFromHex(data['color'] ?? '#3B82F6'),
          'isFeatured': data['isFeatured'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching rewards: $e');
      return _defaultRewards;
    }
  }

  /// Stream rewards for real-time updates
  Stream<List<Map<String, dynamic>>> getRewardsStream() {
    return _db
        .collection('rewards')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return _defaultRewards;

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Reward',
              'subtitle': data['subtitle'] ?? '',
              'cost': data['cost'] ?? 0,
              'icon': _getIconFromName(data['icon'] ?? 'card_giftcard'),
              'color': _getColorFromHex(data['color'] ?? '#3B82F6'),
              'isFeatured': data['isFeatured'] ?? false,
            };
          }).toList();
        });
  }

  /// Seed default rewards to Firestore (admin use)
  Future<void> seedRewards() async {
    final existing = await _db.collection('rewards').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final rewards = [
      {
        'title': 'Starbucks ₹5 Gift Card',
        'subtitle': 'Get your morning coffee fix.',
        'cost': 1200,
        'icon': 'coffee',
        'color': '#795548',
        'order': 1,
        'isActive': true,
        'isFeatured': false,
      },
      {
        'title': 'Spotify Premium Month',
        'subtitle': 'Ad-free music listening.',
        'cost': 2500,
        'icon': 'music_note',
        'color': '#1DB954',
        'order': 2,
        'isActive': true,
        'isFeatured': false,
      },
      {
        'title': 'Discord Nitro Basic',
        'subtitle': 'Enhance your chat experience.',
        'cost': 800,
        'icon': 'chat_bubble',
        'color': '#7289DA',
        'order': 3,
        'isActive': true,
        'isFeatured': false,
      },
      {
        'title': '₹10 Google Play Code',
        'subtitle': 'Use for apps or games.',
        'cost': 2000,
        'icon': 'card_giftcard',
        'color': '#34A853',
        'order': 0,
        'isActive': true,
        'isFeatured': true,
      },
    ];

    for (var reward in rewards) {
      await _db.collection('rewards').add(reward);
    }
  }

  // Helper: Convert icon name to IconData
  IconData _getIconFromName(String name) {
    const iconMap = {
      'coffee': Icons.coffee,
      'music_note': Icons.music_note,
      'chat_bubble': Icons.chat_bubble,
      'card_giftcard': Icons.card_giftcard,
      'shopping_cart': Icons.shopping_cart,
    };
    return iconMap[name] ?? Icons.card_giftcard;
  }

  // Helper: Convert hex color to Color
  Color _getColorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Default fallback rewards
  List<Map<String, dynamic>> get _defaultRewards => [
    {
      'id': 'starbucks',
      'title': 'Starbucks ₹5 Gift Card',
      'subtitle': 'Get your morning coffee fix.',
      'cost': 1200,
      'icon': Icons.coffee,
      'color': Colors.brown,
      'isFeatured': false,
    },
    {
      'id': 'spotify',
      'title': 'Spotify Premium Month',
      'subtitle': 'Ad-free music listening.',
      'cost': 2500,
      'icon': Icons.music_note,
      'color': Colors.green,
      'isFeatured': false,
    },
    {
      'id': 'discord',
      'title': 'Discord Nitro Basic',
      'subtitle': 'Enhance your chat experience.',
      'cost': 800,
      'icon': Icons.chat_bubble,
      'color': Colors.purpleAccent,
      'isFeatured': false,
    },
  ];
}
