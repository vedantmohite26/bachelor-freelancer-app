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

class _JobWithDistance {
  final Map<String, dynamic> job;
  final String distanceDisplay;

  const _JobWithDistance({
    required this.job,
    required this.distanceDisplay,
  });
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  static const double _maxRadiusKm = 10.0; // 10 km radius filter
  bool _isMapView = false;
  Position? _currentPosition;
  Set<String> _appliedJobIds = {};
  StreamSubscription? _applicationsSubscription;
  Stream<List<Map<String, dynamic>>>? _jobsStream;
  String? _cachedUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToApplications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.user?.uid;
    // Cache stream instance to prevent re-subscribing on widget rebuilds
    if (_jobsStream == null || _cachedUserId != currentUserId) {
      _cachedUserId = currentUserId;
      _jobsStream = Provider.of<FirestoreService>(context, listen: false)
          .getJobsStream(currentUserId: currentUserId);
    }
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
              stream: _jobsStream,
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

                // Performance optimization: Consolidate distance calculation & string formatting
                // into a single pass per snapshot instead of repeating trigonometric math on every scroll frame.
                final List<_JobWithDistance> formattedJobs = [];
                for (final job in allJobs) {
                  String distanceDisplay = "...";
                  bool isWithinRadius = true;
                  if (_currentPosition != null &&
                      job['latitude'] != null &&
                      job['longitude'] != null) {
                    try {
                      final distMeters = Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        job['latitude'],
                        job['longitude'],
                      );
                      if (distMeters > _maxRadiusKm * 1000) {
                        isWithinRadius = false;
                      } else if (distMeters < 1000) {
                        distanceDisplay = "${distMeters.toStringAsFixed(0)} m";
                      } else {
                        distanceDisplay =
                            "${(distMeters / 1000).toStringAsFixed(1)} km";
                      }
                    } catch (_) {}
                  }
                  if (isWithinRadius) {
                    formattedJobs.add(
                      _JobWithDistance(
                        job: job,
                        distanceDisplay: distanceDisplay,
                      ),
                    );
                  }
                }

                if (_isMapView) {
                  return MapScreen(
                    onToggleView: _toggleView,
                    jobs: formattedJobs.map((e) => e.job).toList(),
                  );
                }
                return Column(
                  children: [
                    SizedBox(height: 16.h),
                    if (formattedJobs.isEmpty)
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
                          cacheExtent: 500,
                          addRepaintBoundaries: true,
                          itemCount: formattedJobs.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final item = formattedJobs[index];
                            final job = item.job;
                            String timeDisplay = job['time'] ?? "Flexible";
                            return JobCard(
                              key: ValueKey(job['id'] ?? 'job_$index'),
                              title: job['title'] ?? 'Untitled Job',
                              price: job['price'] ?? 0,
                              distance: item.distanceDisplay,
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
