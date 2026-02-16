import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = false;
  bool _hasApplied = false;
  bool _checkingApplication = true;
  Map<String, dynamic>? _seekerProfile;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
    _loadSeekerProfile();
    _calculateDistance();
  }

  Future<void> _checkApplicationStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final jobService = Provider.of<JobService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) {
      if (mounted) setState(() => _checkingApplication = false);
      return;
    }

    try {
      final hasApplied = await jobService.hasAppliedToJob(
        widget.job['id'],
        userId,
      );

      if (mounted) {
        setState(() {
          _hasApplied = hasApplied;
          _checkingApplication = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
      if (mounted) {
        setState(() => _checkingApplication = false);
      }
    }
  }

  Future<void> _loadSeekerProfile() async {
    final userService = Provider.of<UserService>(context, listen: false);
    try {
      final posterId = widget.job['posterId'] as String?;
      if (posterId != null) {
        final profile = await userService.getUserProfile(posterId);
        if (mounted) {
          setState(() => _seekerProfile = profile);
        }
      }
    } catch (e) {
      debugPrint('Error loading seeker profile: $e');
    }
  }

  Future<void> _calculateDistance() async {
    final jobLat = widget.job['latitude'] as double?;
    final jobLng = widget.job['longitude'] as double?;

    if (jobLat != null && jobLng != null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }

        if (permission == LocationPermission.deniedForever) return;

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5), // Add timeout
          ),
        );
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          jobLat,
          jobLng,
        );
        if (mounted) {
          setState(() => _distanceKm = distanceMeters / 1000);
        }
      } catch (e) {
        debugPrint('Error calculating distance: $e');
      }
    }
  }

  Future<void> _applyForJob() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to apply for jobs")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final userService = Provider.of<UserService>(context, listen: false);

      // Apply for the job
      await jobService.applyForJob(widget.job['id'], user.uid);

      // Get helper's name for notification
      final helperProfile = await userService.getUserProfile(user.uid);
      final helperName = helperProfile?['name'] ?? 'A helper';

      // Notify the seeker about the new application
      final posterId = widget.job['posterId'] as String?;
      if (posterId != null) {
        await notificationService.createNotification(
          userId: posterId,
          title: 'New Application',
          subtitle: '$helperName applied for "${widget.job['title']}"',
          type: 'job',
          relatedId: widget.job['id'],
        );
      }

      if (mounted) {
        setState(() {
          _hasApplied = true;
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.growthGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppTheme.growthGreen,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Application Sent!",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your application for \"${widget.job['title']}\" has been submitted. The seeker will review it shortly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Great!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seekerName = _seekerProfile?['name'] ?? 'Unknown';
    final seekerPhone = _seekerProfile?['phoneNumber'] ?? 'Not provided';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Job Details",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(widget.job['category'] ?? 'General'),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
                Text(
                  "₹${widget.job['price']}",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.growthGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment Type & Distance Row
            Row(
              children: [
                // Payment Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.job['priceType'] == 'hourly'
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.job['priceType'] == 'hourly'
                            ? Icons.access_time
                            : Icons.payments,
                        size: 16,
                        color: widget.job['priceType'] == 'hourly'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.job['priceType'] == 'hourly'
                            ? 'Hourly'
                            : 'Fixed',
                        style: TextStyle(
                          color: widget.job['priceType'] == 'hourly'
                              ? Colors.orange
                              : Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Distance Badge
                if (_distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 16,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _distanceKm! < 1
                              ? '${(_distanceKm! * 1000).toStringAsFixed(0)} m away'
                              : '${_distanceKm!.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Job Title
            Text(
              widget.job['title'] ?? 'No Title',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.job['date'] != null
                              ? DateFormat(
                                  'EEE, d MMM',
                                ).format(DateTime.parse(widget.job['date']))
                              : 'Date TBA',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.job['time'] ?? 'Time TBA',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location
            InkWell(
              onTap: () async {
                final lat = widget.job['latitude'];
                final lng = widget.job['longitude'];
                if (lat != null && lng != null) {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open map')),
                      );
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.job['address'] ?? 'Location not specified',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Tap to view on map",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seeker Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Posted By",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        radius: 24,
                        child: Text(
                          seekerName.isNotEmpty
                              ? seekerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seekerName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  seekerPhone,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              "Description",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.job['description'] ?? 'No description provided.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Map Location (if coordinates available)
            if (widget.job['latitude'] != null &&
                widget.job['longitude'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.job['latitude'],
                            widget.job['longitude'],
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('job_location'),
                            position: LatLng(
                              widget.job['latitude'],
                              widget.job['longitude'],
                            ),
                            infoWindow: InfoWindow(
                              title: widget.job['title'] ?? 'Job Location',
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Apply Button
            _buildApplyButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(ColorScheme colorScheme) {
    if (_checkingApplication) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasApplied) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.growthGreen),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppTheme.growthGreen),
              SizedBox(width: 8),
              Text(
                "Applied",
                style: TextStyle(
                  color: AppTheme.growthGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        await _applyForJob();
        // Return false to keep the widget in tree (state update will change UI to 'Applied')
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E), // Green
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              "Applied!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Swipe to Apply",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.keyboard_double_arrow_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
