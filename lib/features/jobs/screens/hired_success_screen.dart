import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:confetti/confetti.dart';

import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'dart:math';

class HiredSuccessScreen extends StatefulWidget {
  final String helperName;
  final String helperImage;
  final String helperEmail;
  final String helperPhoneNumber;
  final String seekerImage; // Optional, can use placeholder
  final String jobId;
  final VoidCallback onGoToChat;
  final VoidCallback onViewTask;

  const HiredSuccessScreen({
    super.key,
    required this.helperName,
    required this.helperImage,
    this.helperEmail = '',
    this.helperPhoneNumber = '',
    this.seekerImage = '',
    required this.jobId,
    required this.onGoToChat,
    required this.onViewTask,
  });

  @override
  State<HiredSuccessScreen> createState() => _HiredSuccessScreenState();
}

class _HiredSuccessScreenState extends State<HiredSuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _playCelebration();
  }

  Future<void> _playCelebration() async {
    // Start confetti
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme for this screen as per design
    final darkTheme = AppTheme.darkTheme(null);

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF101827), // Deep dark blue background
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.yellow,
                Colors.blue,
                Colors.green,
                Colors.pink,
                Colors.orange,
              ],
            ),

            // Close Button
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),

                    // Avatars & Handshake
                    SizedBox(
                      height: 120.h,
                      width: 200.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Seeker (Left)
                          Positioned(
                            left: 20,
                            child: _buildAvatar(
                              widget.seekerImage,
                              Colors.blue,
                            ),
                          ),
                          // Helper (Right)
                          Positioned(
                            right: 20,
                            child: _buildAvatar(
                              widget.helperImage,
                              Colors.yellow,
                            ),
                          ),
                          // Handshake Icon (Center, Top)
                          Positioned(
                            top: -10,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: Icon(
                                Icons.handshake,
                                color: const Color(0xFFFFD700), // Gold
                                size: 32.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: "You've Hired "),
                          TextSpan(
                            text: "${widget.helperName}!",
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                            ), // Blue
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      "Great choice. Let's get this task started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Timeline Card
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937), // Lighter dark
                        borderRadius: BorderRadius.circular(16.w),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        children: [
                          _buildTimelineItem(
                            icon: Icons.check,
                            iconColor: Colors.white,
                            iconBg: Colors.blue[600]!,
                            title: "Chat channel created",
                            subtitle:
                                "You can now message ${widget.helperName} directly.",
                            isLast: false,
                          ),
                          _buildTimelineItem(
                            icon: Icons.lock,
                            iconColor: Colors.black,
                            iconBg: Colors.yellow[600]!,
                            title: "Funds held in Escrow",
                            subtitle:
                                "Payment is secure until the task is done.",
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Helper Contact Details Card
                    if (widget.helperEmail.isNotEmpty ||
                        widget.helperPhoneNumber.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.contact_phone,
                                  color: Colors.blue[400],
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Helper Contact Details',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[200],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            if (widget.helperPhoneNumber.isNotEmpty)
                              _buildContactRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: widget.helperPhoneNumber,
                              ),
                            if (widget.helperEmail.isNotEmpty) ...[
                              if (widget.helperPhoneNumber.isNotEmpty)
                                SizedBox(height: 12.h),
                              _buildContactRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: widget.helperEmail,
                              ),
                            ],
                          ],
                        ),
                      ),

                    SizedBox(height: 40.h),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onGoToChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB), // Blue
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.w),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Go to Chat",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.chat_bubble_outline, size: 20.sp),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    TextButton(
                      onPressed: widget.onViewTask,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "View Task Details",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String imageUrl, Color borderColor) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CachedNetworkAvatar(
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        radius: 40,
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconBg, size: 20.sp),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: Colors.grey[800],
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                ),
                if (!isLast) SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Icon(icon, color: Colors.white70, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1, // Add limit to prevent multiline overflow
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis (...) for long text
              ),
            ],
          ),
        ),
      ],
    );
  }
}
