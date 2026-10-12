import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryService {
  final FirebaseFirestore _db;
  List<Map<String, dynamic>>? _cachedCategories;

  CategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Clear the in-memory categories cache
  void clearCache() {
    _cachedCategories = null;
  }

  /// Deep-copy helper to ensure callers cannot mutate internal cache references
  List<Map<String, dynamic>> _deepCopyCategories(
    List<Map<String, dynamic>> categories,
  ) {
    return categories
        .map((cat) => Map<String, dynamic>.from(cat))
        .toList();
  }

  /// Fetch all categories from Firestore
  /// Uses in-memory caching to prevent redundant Firestore queries
  /// Returns a list of category maps with: id, title, icon, color, bgColor
  Future<List<Map<String, dynamic>>> getCategories() async {
    if (_cachedCategories != null) {
      return _deepCopyCategories(_cachedCategories!);
    }

    try {
      final snapshot = await _db
          .collection('categories')
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        _cachedCategories = _defaultCategories;
        return _deepCopyCategories(_cachedCategories!);
      }

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Category',
          'icon': _getIconFromName(data['icon'] ?? 'help'),
          'color': _getColorFromHex(data['color'] ?? '#3B82F6'),
          'bgColor': _getColorFromHex(data['bgColor'] ?? '#DBEAFE'),
        };
      }).toList();

      _cachedCategories = categories;
      return _deepCopyCategories(_cachedCategories!);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      _cachedCategories = _defaultCategories;
      return _deepCopyCategories(_cachedCategories!);
    }
  }

  /// Stream categories for real-time updates
  /// Updates the in-memory cache whenever a new snapshot is received
  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    return _db.collection('categories').orderBy('order').snapshots().map((
      snapshot,
    ) {
      if (snapshot.docs.isEmpty) {
        _cachedCategories = _defaultCategories;
        return _deepCopyCategories(_cachedCategories!);
      }

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Category',
          'icon': _getIconFromName(data['icon'] ?? 'help'),
          'color': _getColorFromHex(data['color'] ?? '#3B82F6'),
          'bgColor': _getColorFromHex(data['bgColor'] ?? '#DBEAFE'),
        };
      }).toList();

      _cachedCategories = categories;
      return _deepCopyCategories(_cachedCategories!);
    });
  }

  /// Seed default categories to Firestore (admin use)
  Future<void> seedCategories() async {
    final existing = await _db.collection('categories').limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final categories = [
      {
        'title': 'Cleaning',
        'icon': 'cleaning_services',
        'color': '#AE7EDE',
        'bgColor': '#F3E8FF',
        'order': 1,
      },
      {
        'title': 'Tech Support',
        'icon': 'computer',
        'color': '#3B82F6',
        'bgColor': '#DBEAFE',
        'order': 2,
      },
      {
        'title': 'Delivery',
        'icon': 'local_shipping',
        'color': '#F97316',
        'bgColor': '#FFEDD5',
        'order': 3,
      },
      {
        'title': 'Tutor',
        'icon': 'menu_book',
        'color': '#10B981',
        'bgColor': '#D1FAE5',
        'order': 4,
      },
      {
        'title': 'Moving',
        'icon': 'vertical_align_top',
        'color': '#F59E0B',
        'bgColor': '#FEF3C7',
        'order': 5,
      },
      {
        'title': 'Grocery',
        'icon': 'shopping_basket',
        'color': '#EF4444',
        'bgColor': '#FEE2E2',
        'order': 6,
      },
    ];

    for (var cat in categories) {
      await _db.collection('categories').add(cat);
    }
    clearCache();
  }

  // Helper: Convert icon name to IconData
  IconData _getIconFromName(String name) {
    const iconMap = {
      'cleaning_services': Icons.cleaning_services_outlined,
      'computer': Icons.computer,
      'monitor': Icons.monitor,
      'local_shipping': Icons.local_shipping_outlined,
      'menu_book': Icons.menu_book,
      'vertical_align_top': Icons.vertical_align_top,
      'shopping_basket': Icons.shopping_basket_outlined,
      'help': Icons.help_outline,
    };
    return iconMap[name] ?? Icons.help_outline;
  }

  // Helper: Convert hex color to Color
  Color _getColorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Default fallback categories
  List<Map<String, dynamic>> get _defaultCategories => [
    {
      'id': 'cleaning',
      'title': 'Cleaning',
      'icon': Icons.cleaning_services_outlined,
      'color': const Color(0xFFAE7EDE),
      'bgColor': const Color(0xFFF3E8FF),
    },
    {
      'id': 'tech',
      'title': 'Tech Support',
      'icon': Icons.monitor,
      'color': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
    {
      'id': 'delivery',
      'title': 'Delivery',
      'icon': Icons.local_shipping_outlined,
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFFFEDD5),
    },
    {
      'id': 'tutor',
      'title': 'Tutor',
      'icon': Icons.menu_book,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFD1FAE5),
    },
    {
      'id': 'moving',
      'title': 'Moving',
      'icon': Icons.vertical_align_top,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFEF3C7),
    },
    {
      'id': 'grocery',
      'title': 'Grocery',
      'icon': Icons.shopping_basket_outlined,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFEE2E2),
    },
  ];
}
