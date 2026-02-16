import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onToggleView;
  final List<Map<String, dynamic>> jobs;

  const MapScreen({
    super.key,
    required this.onToggleView,
    this.jobs = const [],
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  bool _waitingForGps = false;
  Position? _currentPosition;

  // New Delhi Default
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 12,
  );

  CameraPosition _initialPosition = _defaultPosition;

  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMapStyles();
    _loadJobMarkers();
    _checkLocationAndInit();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/styles/map_style_dark.json');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _waitingForGps = false;
      _checkLocationAndInit();
    }
  }

  double _getCategoryHue(String? category) {
    if (category == null) return BitmapDescriptor.hueBlue;

    switch (category.toLowerCase()) {
      case 'moving':
        return BitmapDescriptor.hueViolet;
      case 'cleaning':
        return BitmapDescriptor.hueCyan;
      case 'yard work':
        return BitmapDescriptor.hueGreen;
      case 'tech':
        return BitmapDescriptor.hueOrange;
      case 'delivery':
        return BitmapDescriptor.hueRed;
      default:
        // Generate a consistent unique hue for custom categories
        // Hash the string and map it to 0-360 range
        final int hash = category.toLowerCase().codeUnits.fold(
          0,
          (prev, char) => prev + char,
        );
        final double hue = (hash % 360).toDouble();
        return hue;
    }
  }

  void _loadJobMarkers() {
    setState(() {
      _markers.clear();
      for (var job in widget.jobs) {
        if (job['latitude'] != null && job['longitude'] != null) {
          final double jobLat = (job['latitude'] as num).toDouble();
          final double jobLng = (job['longitude'] as num).toDouble();

          // Filter by distance if we have user location
          if (_currentPosition != null) {
            final double distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              jobLat,
              jobLng,
            );

            // 50km = 50,000 meters
            if (distanceInMeters > 50000) {
              continue;
            }
          }

          _markers.add(
            Marker(
              markerId: MarkerId(job['id'] ?? job.hashCode.toString()),
              position: LatLng(jobLat, jobLng),
              infoWindow: InfoWindow(
                title: job['title'] ?? 'Job',
                snippet:
                    '₹${job['price'] ?? 0} • ${job['category'] ?? 'General'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getCategoryHue(job['category']),
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _checkLocationAndInit() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    try {
      final position = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (position != null) {
            _initialPosition = CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 12, // Zoom out a bit to see area
            );
          }
          _isLoadingLocation = false;
        });

        // Load markers after we (potentially) have location for filtering
        _loadJobMarkers();

        if (position != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      // Even if location fails, load markers (will show all or default logic)
      _loadJobMarkers();
      _showEnableGpsDialog(e.toString());
    }
  }

  void _showEnableGpsDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable GPS'),
        content: Text(
          message.contains('disabled')
              ? 'Please enable GPS system to continue and see jobs near you.'
              : 'Location permission is required to show nearby jobs.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Use Default Location'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final locationService = Provider.of<LocationService>(
                context,
                listen: false,
              );
              _waitingForGps = true;
              await locationService.openLocationSettings();
              // Execution continues, but re-check happens in didChangeAppLifecycleState
            },
            child: const Text('Turn On GPS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: (Theme.of(context).brightness == Brightness.dark)
                ? _darkMapStyle
                : null,
            onMapCreated: (controller) => _mapController = controller,
          ),

          if (_isLoadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),

          // Bottom area for job preview (could be aPageView)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_screen_fab',
        onPressed: _checkLocationAndInit,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
