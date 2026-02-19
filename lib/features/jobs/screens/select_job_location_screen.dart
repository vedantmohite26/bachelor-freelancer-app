import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/location_service.dart';

class SelectJobLocationScreen extends StatefulWidget {
  const SelectJobLocationScreen({super.key});

  @override
  State<SelectJobLocationScreen> createState() =>
      _SelectJobLocationScreenState();
}

class _SelectJobLocationScreenState extends State<SelectJobLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = true;
  String? _darkMapStyle;

  // New Delhi Default
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14,
  );

  CameraPosition _initialPosition = _defaultPosition;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _getCurrentLocation();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/styles/map_style_dark.json');
    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    try {
      final position = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          if (position != null) {
            _initialPosition = CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14,
            );
            _selectedLocation = LatLng(position.latitude, position.longitude);
          }
          _isLoadingLocation = false;
        });

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
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _onConfirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Job Location'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: _onConfirmLocation,
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: (Theme.of(context).brightness == Brightness.dark)
                ? _darkMapStyle
                : null,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
          ),

          if (_isLoadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),

          // Instruction card at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Tap on the map to select job location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Selected location info card at bottom
          if (_selectedLocation != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'select_job_loc_fab',
        onPressed: _getCurrentLocation,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
