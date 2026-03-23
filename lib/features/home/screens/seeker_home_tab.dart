import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/location_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';
import 'package:freelancer/features/chat/screens/chat_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';

class SeekerHomeTab extends StatefulWidget {
  const SeekerHomeTab({super.key});

  @override
  State<SeekerHomeTab> createState() => _SeekerHomeTabState();
}

class _SeekerHomeTabState extends State<SeekerHomeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _currentLocation = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final position = await locationService.getCurrentLocation();
      if (mounted && position != null) {
        setState(() {
          _currentLocation =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      } else if (mounted) {
        setState(() {
          _currentLocation = "Location unavailable";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = "Error fetching location";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // 1. App Bar with Location & Greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _showLocationPicker,
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: AppTheme.primaryBlue,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Location",
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            _currentLocation,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16.sp,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildIconBtn(
                                  Icons.chat_bubble_outline,
                                  onTap: _navigateToMessages,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Title
                        Text(
                          "What do you need\nhelp with today?",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: Theme.of(
                              context,
                            ).textTheme.displayMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Nearby Helpers Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Nearby Helpers",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showHelperFilters,
                          child: const Icon(
                            Icons.filter_list,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                // 4. Helpers List (Real-time data)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: userService.getNearbyHelpers(limit: 20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Column(
                          children: [
                            ShimmerCard(),
                            ShimmerCard(),
                            ShimmerCard(),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text("Error loading helpers")),
                      );
                    }

                    final helpers = snapshot.data ?? [];

                    // Apply search filter (Mock data augmentation for demo if empty)
                    // If no real helpers, we might want to show dummy ones to match design for demo
                    // But here we stick to real data + filter
                    final filteredHelpers = helpers;

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final helper = filteredHelpers[index];
                        final helperId = helper['id'] as String;

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HelperProfileScreen(helperId: helperId),
                                ),
                              );
                            },
                            child: _HelperCard(
                              name: helper['name'] ?? 'Unknown',
                              role:
                                  "Comp Sci Student • Tech Support", // Dynamic later
                              rating: (helper['rating'] ?? 0.0).toDouble(),
                              reviewCount: helper['reviewCount'] ?? 0,
                              distance: '0.2',
                              isVerified: helper['verifiedStudent'] ?? false,
                            ),
                          ),
                        );
                      }, childCount: filteredHelpers.length),
                    );
                  },
                ),

                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),

            // Floating "Quick Post" Button
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(
    IconData icon, {
    bool isOrange = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22.sp,
          color: isOrange
              ? AppTheme.coinYellow
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  // Navigation methods

  void _navigateToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  // Bottom sheet methods
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).bottomSheetTheme.backgroundColor ??
              Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Select Location",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(
                Icons.my_location,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Use Current Location'),
              onTap: () {
                Navigator.pop(context);
                _updateLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location updated')),
                );
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showHelperFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).bottomSheetTheme.backgroundColor ??
              Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Filter Helpers",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
            const _FilterOption(title: 'Sort By', value: 'Nearest First'),
            const _FilterOption(title: 'Availability', value: 'Available Now'),
            const _FilterOption(title: 'Rating', value: 'All Ratings'),
            const _FilterOption(title: 'Experience', value: 'Any'),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters applied')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text('Apply Filters'),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  final String name;
  final String role;
  final double rating;
  final int reviewCount;
  final String distance;
  final bool isVerified;

  const _HelperCard({
    required this.name,
    required this.role,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              CachedNetworkAvatar(
                radius: 28,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppTheme.growthGreen, // Online
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (isVerified)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.growthGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.w),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12.sp,
                              color: AppTheme.growthGreen,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "Verified",
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.growthGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(width: 12.w),
                    Icon(Icons.star, size: 14.sp, color: AppTheme.coinYellow),
                    SizedBox(width: 4.w),
                    Text(
                      "${rating.toStringAsFixed(1)} ($reviewCount)",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Location
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14.sp,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    "$distance mi",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Filter option widget for bottom sheets
class _FilterOption extends StatelessWidget {
  final String title;
  final String value;

  const _FilterOption({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
