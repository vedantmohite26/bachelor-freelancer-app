import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/features/jobs/widgets/job_card.dart';
import 'package:freelancer/features/maps/screens/map_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'dart:async';
import 'package:freelancer/core/widgets/shimmer_widgets.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  static const double _maxRadiusKm = 10.0; // 10 km radius filter
  bool _isMapView = false;
  Position? _currentPosition;
  Set<String> _appliedJobIds = {};
  StreamSubscription? _applicationsSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToApplications();
    });
  }

  void _subscribeToApplications() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final jobService = Provider.of<JobService>(context, listen: false);
      final user = authService.user;

      if (user != null) {
        _applicationsSubscription = jobService
            .getAllHelperApplications(user.uid)
            .listen(
              (apps) {
                if (mounted) {
                  setState(() {
                    _appliedJobIds = apps
                        .map((a) => a['jobId'] as String)
                        .toSet();
                  });
                }
              },
              onError: (e) {
                debugPrint("Error fetching applications: $e");
              },
            );
      }
    } catch (e) {
      debugPrint("Error setting up application subscription: $e");
    }
  }

  @override
  void dispose() {
    _applicationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _toggleView() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = colorScheme.surface;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;
    final primaryBlue = colorScheme.primary;

    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.user?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.location_on, color: primaryBlue, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              _currentPosition != null
                  ? "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}"
                  : "Fetching location...",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.w),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isMapView) _toggleView();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: !_isMapView ? primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list,
                              color: !_isMapView
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "List View",
                              style: TextStyle(
                                color: !_isMapView
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_isMapView) _toggleView();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _isMapView ? primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: _isMapView
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Map View",
                              style: TextStyle(
                                color: _isMapView
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<FirestoreService>(
                context,
              ).getJobsStream(currentUserId: currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerListScreen();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }
                final allJobs = snapshot.data ?? [];

                // Process jobs: Calculate distance once, filter, and sort
                final jobs = allJobs.map((job) {
                  double? distMeters;
                  String distanceDisplay = "...";

                  if (_currentPosition != null &&
                      job['latitude'] != null &&
                      job['longitude'] != null) {
                    try {
                      distMeters = Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        job['latitude'],
                        job['longitude'],
                      );
                      if (distMeters < 1000) {
                        distanceDisplay = "${distMeters.toStringAsFixed(0)} m";
                      } else {
                        distanceDisplay =
                            "${(distMeters / 1000).toStringAsFixed(1)} km";
                      }
                    } catch (_) {}
                  }

                  // Create a new map to avoid modifying the original from Firestore
                  return {
                    ...job,
                    '_distanceMeters': distMeters,
                    '_distanceDisplay': distanceDisplay,
                  };
                }).where((job) {
                  // Filter by radius if position is available
                  final dist = job['_distanceMeters'] as double?;
                  if (dist == null) return true; // Keep jobs without location
                  return dist <= _maxRadiusKm * 1000;
                }).toList();

                // Sort by distance (closest first)
                jobs.sort((a, b) {
                  final da = a['_distanceMeters'] as double? ?? double.infinity;
                  final db = b['_distanceMeters'] as double? ?? double.infinity;
                  return da.compareTo(db);
                });

                if (_isMapView) {
                  return MapScreen(onToggleView: _toggleView, jobs: jobs);
                }
                return Column(
                  children: [
                    SizedBox(height: 16.h),
                    if (jobs.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            "No jobs found nearby.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          cacheExtent:
                              500, // Pre-render cards off-screen for smoother scrolling
                          addRepaintBoundaries: true,
                          itemCount: jobs.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            final distanceDisplay =
                                job['_distanceDisplay'] as String? ?? "...";
                            String timeDisplay = job['time'] ?? "Flexible";
                            return JobCard(
                              key: ValueKey(job['id'] ?? 'job_$index'),
                              title: job['title'] ?? 'Untitled Job',
                              price: job['price'] ?? 0,
                              distance: distanceDisplay,
                              category: job['category'] ?? 'General',
                              time: timeDisplay,
                              jobData: job,
                              isApplied: _appliedJobIds.contains(job['id']),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
