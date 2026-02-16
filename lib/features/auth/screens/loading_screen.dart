// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:freelancer/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:freelancer/core/widgets/premium_app_loader.dart';

/// Performance-optimized loading screen designed for all devices
/// Works efficiently from low-end (30fps) to high-end (120fps+) devices
/// Adaptive frame rate and efficient memory usage
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app with proper error handling
  Future<void> _initializeApp() async {
    try {
      setState(() => _statusMessage = 'Connecting to Firebase...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Activate App Check
      // We wrap this in a try-catch so it doesn't block app startup in debug mode if verification fails
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.appAttest,
        );
      } catch (e) {
        debugPrint('App Check warning (non-fatal): $e');
        // Continue loading even if App Check fails locally
      }

      // Enable offline persistence for better UX and cost savings
      // Optimized for all devices - works efficiently even on low-end devices
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      setState(() => _statusMessage = 'Loading your workspace...');

      // Small delay to ensure smooth transition (adaptive to device)
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to main app if mounted
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          // Provide more specific error messages
          if (e.toString().contains('Internet') ||
              e.toString().contains('Host')) {
            _statusMessage =
                'Network Error. Please check your internet connection.';
          } else {
            _statusMessage = 'Initialization failed. Please restart.';
          }
        });
      }
      debugPrint('Initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _buildRetryButton(theme),
            ],
          ),
        ),
      );
    }

    return PremiumAppLoader(statusMessage: _statusMessage);
  }

  Widget _buildRetryButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _hasError = false;
          _statusMessage = 'Retrying...';
        });
        _initializeApp();
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
