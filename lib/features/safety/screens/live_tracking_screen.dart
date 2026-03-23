import 'dart:async';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const LiveTrackingScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  StreamSubscription? _locationSubscription;
  String? _statusMessage;

  // Default to New Delhi if no location yet
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.targetUserId);

    _locationSubscription = docRef.snapshots().listen(
      (snapshot) {
        if (!mounted) return;

        if (!snapshot.exists) {
          setState(() => _statusMessage = "User not found");
          return;
        }

        final data = snapshot.data();
        final isSharing = data?['isSharingLocation'] == true;
        final location = data?['currentLocation'] as Map<String, dynamic>?;

        if (!isSharing || location == null) {
          setState(() {
            _markers.clear();
            _statusMessage = "${widget.targetUserName} is not sharing location";
          });
          return;
        }

        // Update Marker
        final lat = location['latitude'] as double;
        final lng = location['longitude'] as double;
        final timestamp = (location['timestamp'] as Timestamp?)?.toDate();
        final speed = location['speed'] as double? ?? 0.0;

        final latLng = LatLng(lat, lng);

        setState(() {
          _statusMessage = null; // Clear error/status if sharing active
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId(widget.targetUserId),
              position: latLng,
              infoWindow: InfoWindow(
                title: widget.targetUserName,
                snippet:
                    "Speed: ${speed.toStringAsFixed(1)} m/s • ${timestamp != null ? _formatTime(timestamp) : 'Just now'}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          );
        });

        // Animate Camera
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      },
      onError: (e) {
        if (mounted) setState(() => _statusMessage = "Error connecting: $e");
      },
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tracking ${widget.targetUserName}"),
            if (_statusMessage == null)
              Text(
                "Live Location",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            mapType: MapType.normal,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          if (_statusMessage != null)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  margin: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.w),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Go Back"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Status Pill at Bottom
          if (_statusMessage == null && _markers.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(30.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.h,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Sharing location live...",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
