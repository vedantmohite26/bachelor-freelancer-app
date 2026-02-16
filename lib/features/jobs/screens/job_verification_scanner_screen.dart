import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/job_service.dart';

class JobVerificationScannerScreen extends StatefulWidget {
  final String jobId;
  final String helperId;
  final String helperName;

  /// 'start' to verify & start job, 'complete' to verify & complete job
  final String mode;

  const JobVerificationScannerScreen({
    super.key,
    required this.jobId,
    required this.helperId,
    required this.helperName,
    this.mode = 'start',
  });

  @override
  State<JobVerificationScannerScreen> createState() =>
      _JobVerificationScannerScreenState();
}

class _JobVerificationScannerScreenState
    extends State<JobVerificationScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;
  bool _isSuccess = false;
  Map<String, dynamic>? _scannedHelperInfo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyQrCode(String? scannedCode) async {
    if (_isProcessing || scannedCode == null) return;

    setState(() => _isProcessing = true);

    try {
      final jobService = Provider.of<JobService>(context, listen: false);

      // Try to parse as JSON (new format)
      String token;
      Map<String, dynamic>? helperInfo;
      try {
        final decoded = jsonDecode(scannedCode);
        if (decoded is Map<String, dynamic>) {
          token = decoded['token'] as String;
          helperInfo = decoded;
        } else {
          token = scannedCode; // fallback to raw string
        }
      } catch (_) {
        token = scannedCode; // fallback for old plain-token QR codes
      }

      if (widget.mode == 'complete') {
        await jobService.verifyAndCompleteJob(widget.jobId, token);
      } else {
        await jobService.verifyAndStartJob(widget.jobId, token);
      }

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _scannedHelperInfo = helperInfo;
        });

        if (widget.mode == 'complete') {
          // Return immediately with helper info for payment flow
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(
              context,
            ).pop({'verified': true, 'helperInfo': helperInfo});
          }
        } else {
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      final helperName = _scannedHelperInfo?['helperName'] ?? widget.helperName;
      final helperPhone = _scannedHelperInfo?['helperPhone'];
      final isComplete = widget.mode == 'complete';

      return Scaffold(
        backgroundColor: isComplete
            ? const Color(0xFF3B82F6)
            : const Color(0xFF10B981),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isComplete ? Icons.payments_rounded : Icons.check_circle,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                isComplete ? "Job Verified!" : "Verified!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isComplete
                    ? "Proceeding to payment..."
                    : "Job started with $helperName",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (!isComplete &&
                  helperPhone != null &&
                  helperPhone != 'N/A') ...[
                const SizedBox(height: 4),
                Text(
                  helperPhone,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'complete'
              ? "Scan Completion QR"
              : "Scan Helper's QR Code",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _verifyQrCode(barcode.rawValue);
              }
            },
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    widget.mode == 'complete'
                        ? "Scan completion QR to end job"
                        : "Scan ${widget.helperName}'s QR Code",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.mode == 'complete'
                      ? "Helper's completion QR will verify job is done"
                      : "Ask the helper to show their QR code from their profile",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Flashlight Toggle
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on, size: 32),
                color: Colors.white,
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Custom overlay shape to mimic default scanner overlay but customizable
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top +
          height / 2 -
          mCutOutSize / 2 +
          borderOffset -
          cutOutBottomOffset,
      mCutOutSize - borderWidth,
      mCutOutSize - borderWidth,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw corners
    final path = Path();

    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.arcToPoint(
      Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
