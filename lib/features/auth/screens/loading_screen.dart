// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:freelancer/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:freelancer/core/widgets/premium_app_loader.dart';

/// Performance-optimized loading screen with progress bar illusion.
/// The bar advances faster than real init to create perceived speed.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  String _statusMessage = 'Initializing...';
  bool _hasError = false;
  double _progress = 0.0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  /// Smoothly animate progress to a target value
  void _setProgress(double target) {
    if (!mounted) return;
    setState(() => _progress = target);
  }

  /// Initialize app with progress bar illusion
  Future<void> _initializeApp() async {
    try {
      // Stage 1: Instant progress burst (illusion of speed)
      _setProgress(0.3);
      setState(() => _statusMessage = 'Connecting to Firebase...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _setProgress(0.55);

      // Activate App Check
      setState(() => _statusMessage = 'Securing connection...');
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
      }
      _setProgress(0.8);

      // Configure Firestore with 50MB cache limit (was unlimited)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 50 * 1024 * 1024, // 50MB cap
      );

      setState(() => _statusMessage = 'Loading your workspace...');
      _setProgress(0.95);

      // Brief delay for smooth visual transition
      await Future.delayed(const Duration(milliseconds: 300));
      _setProgress(1.0);

      // Small extra pause so user sees 100%
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate to main app if mounted
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
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

    return Stack(
      children: [
        PremiumAppLoader(statusMessage: _statusMessage),
        // Progress bar overlay at bottom
        Positioned(
          left: 40,
          right: 40,
          bottom: 80,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _hasError = false;
          _statusMessage = 'Retrying...';
          _progress = 0.0;
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
