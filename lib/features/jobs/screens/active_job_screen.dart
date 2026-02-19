import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:freelancer/features/jobs/screens/job_verification_scanner_screen.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';
import 'package:freelancer/features/jobs/screens/upi_payment_screen.dart';
import 'package:freelancer/features/jobs/screens/payment_received_screen.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveJobScreen extends StatefulWidget {
  final bool isSeeker;
  final String? initialJobId;

  const ActiveJobScreen({super.key, required this.isSeeker, this.initialJobId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  // Configurable dependencies logic if needed

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    // Use specific job stream if we have an ID, otherwise use general active jobs stream
    final Stream<List<Map<String, dynamic>>> jobStream =
        (widget.initialJobId != null)
        ? jobService
              .getJobStream(widget.initialJobId!)
              .map((job) => job != null ? [job] : [])
        : jobService.getActiveJobsForUser(userId, isSeeker: widget.isSeeker);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: jobStream,
      builder: (context, snapshot) {
        // If loading and no data yet
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return _buildNoActiveJob(context);
        }

        // Use the first job in the stream (will be the specific one if ID was provided)
        final job = jobs.first;

        final jobId = job['id'];
        final status = job['status'];
        final startedAtTimestamp = job['startedAt'] as Timestamp?;
        final helperName = job['helperName'] ?? "Student Helper";
        final helperAvatar =
            job['helperImage'] ??
            "https://randomuser.me/api/portraits/men/32.jpg";

        // Auto-navigate to success screen if we're a helper and the job is completed
        if (!widget.isSeeker && status == 'completed') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToSuccess(job);
          });
          // Return a placeholder while navigating or keep showing the UI
        }

        // Auto-show QR logic for Seeker
        if (status == 'assigned') {
          final startRequested = job['startRequested'] == true;
          if (!widget.isSeeker && startRequested && !_hasAutoShownQR) {
            _hasAutoShownQR = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                _showStartJobQR(context, jobId, amount);
              }
            });
          }
        }

        return _buildActiveJobUI(
          context: context,
          job: job,
          jobId: jobId,
          status: status,
          helperName: helperName,
          helperAvatar: helperAvatar,
          startedAt: startedAtTimestamp?.toDate(),
        );
      },
    );
  }

  void _navigateToSuccess(Map<String, dynamic> data) {
    if (_hasNavigatedToSuccess) return;

    final amount = (data['price'] as num?)?.toDouble() ?? 0.0;
    final coins = (data['coinsEarned'] as num?)?.toDouble() ?? 0.0;
    final points = (data['pointsEarned'] as num?)?.toInt() ?? 0;
    final title = data['title'] ?? "Job";

    _hasNavigatedToSuccess = true;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentReceivedScreen(
            amount: amount,
            coins: coins,
            points: points,
            jobTitle: title,
          ),
        ),
      );
    }
  }

  Widget _buildNoActiveJob(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No Active Jobs",
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobUI({
    required BuildContext context,
    required Map<String, dynamic> job,
    required String jobId,
    required String status,
    required String helperName,
    required String helperAvatar,
    DateTime? startedAt,
  }) {
    const accentColor = Color(0xFF3B82F6); // Blue 500

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          status == 'in_progress' ? "Session Active" : "Job Details",
          style: GoogleFonts.plusJakartaSans(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 1. Profile / Status Card
              FutureBuilder<Map<String, dynamic>?>(
                future: Provider.of<UserService>(context, listen: false)
                    .getUserProfile(
                      widget.isSeeker
                          ? (job['assignedHelperId'] ?? '')
                          : (job['posterId'] ?? ''),
                    ),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final name =
                      profile?['name'] ??
                      (widget.isSeeker ? "Helper" : "Seeker");
                  final avatar =
                      profile?['profilePicture'] ??
                      (widget.isSeeker ? helperAvatar : "");

                  return GestureDetector(
                    onTap: () => _showSessionDetails(context, job, profile),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 2),
                            ),
                            child: CachedNetworkAvatar(
                              imageUrl: avatar,
                              radius: 28,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'in_progress'
                                            ? Colors.green.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.blue.withValues(
                                                alpha: 0.2,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status == 'assigned'
                                            ? "Waiting to Start"
                                            : "Working Now",
                                        style: TextStyle(
                                          color: status == 'in_progress'
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.tertiary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // 2. Main Timer Display
              if (status == 'in_progress' && startedAt != null)
                JobSessionTimer(startTime: startedAt)
              else if (status == 'assigned')
                Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Ready to Begin",
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),

              const Spacer(flex: 2),

              // 3. Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildButtons(context, status, job),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // State variable to track if QR was already auto-shown
  bool _hasAutoShownQR = false;
  bool _hasNavigatedToSuccess = false;

  @override
  void didUpdateWidget(ActiveJobScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialJobId != widget.initialJobId) {
      _hasAutoShownQR = false;
    }
  }

  Widget _buildButtons(
    BuildContext context,
    String status,
    Map<String, dynamic> job,
  ) {
    final jobId = job['id'];

    // Helper method for cleaner button creation
    Widget buildBtn({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool isPrimary = false,
      Color? color,
    }) {
      return Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? (color ?? Theme.of(context).colorScheme.primary)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
            foregroundColor: isPrimary
                ? (isPrimary && color != null
                      ? Colors.white
                      : Theme.of(context).colorScheme.onPrimary)
                : Theme.of(context).colorScheme.onSurface,
            elevation: isPrimary ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'assigned') {
      return Column(
        children: [
          buildBtn(
            icon: Icons.chat_bubble_outline,
            label: "Chat with ${widget.isSeeker ? 'Helper' : 'Seeker'}",
            onTap: () => _openChat(context, job),
          ),
          if (!widget.isSeeker)
            buildBtn(
              icon: Icons.qr_code,
              label: "Show Verification QR",
              isPrimary: true,
              color: const Color(0xFF10B981), // Green
              onTap: () {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                _showStartJobQR(context, jobId, amount);
              },
            )
          else
            buildBtn(
              icon: Icons.play_arrow_rounded,
              label: "Start Job (Scan QR)",
              isPrimary: true,
              color: const Color(0xFF3B82F6), // Blue
              onTap: () async {
                try {
                  await Provider.of<JobService>(
                    context,
                    listen: false,
                  ).requestJobStart(jobId);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                  return;
                }
                if (context.mounted) _navigateToScanner(context, jobId);
              },
            ),
        ],
      );
    }

    if (status == 'in_progress') {
      return Column(
        children: [
          buildBtn(
            icon: Icons.chat_bubble_outline,
            label: "Chat",
            onTap: () => _openChat(context, job),
          ),
          if (!widget.isSeeker)
            buildBtn(
              icon: Icons.qr_code_2_rounded,
              label: "Finish Job & Show QR",
              isPrimary: true,
              color: const Color(0xFFFFD700), // Gold
              onTap: () {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                _showCompletionQR(context, jobId, amount);
              },
            )
          else
            buildBtn(
              icon: Icons.check_circle_outline,
              label: "Complete & Pay",
              isPrimary: true,
              color: const Color(0xFF10B981), // Green
              onTap: () => _navigateToCompletionScanner(context, job),
            ),
        ],
      );
    }

    if (status == 'payment_pending') {
      return Column(
        children: [
          if (widget.isSeeker)
            buildBtn(
              icon: Icons.payment,
              label: "Proceed to Payment",
              isPrimary: true,
              color: const Color(0xFF10B981),
              onTap: () => _navigateToPayment(context, job),
            )
          else
            Text(
              "Waiting for payment...",
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openChat(BuildContext context, Map<String, dynamic> job) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    if (currentUserId == null) return;

    final otherUserId = widget.isSeeker ? job['helperId'] : job['seekerId'];
    final otherUserName = widget.isSeeker
        ? (job['helperName'] ?? "Student Helper")
        : "Job Provider";

    try {
      final chatId = await chatService.createChat(
        otherUserId,
        currentUserId,
        checkFriendship: false,
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(chatId: chatId, otherUserName: otherUserName),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showStartJobQR(BuildContext context, String jobId, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QRCodeBottomSheet(jobId: jobId, amount: amount),
    );
  }

  Future<void> _navigateToScanner(BuildContext context, String jobId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobVerificationScannerScreen(
          jobId: jobId,
          helperId: "helper", // Needs to be passed ideally
          helperName: "Helper",
          mode: 'start',
        ),
      ),
    );
  }

  void _showCompletionQR(BuildContext context, String jobId, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QRCodeBottomSheet(
          jobId: jobId,
          isCompletion: true,
          amount: amount,
        );
      },
    );
  }

  Future<void> _navigateToCompletionScanner(
    BuildContext context,
    Map<String, dynamic> job,
  ) async {
    final jobId = job['id'] as String;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobVerificationScannerScreen(
          jobId: jobId,
          helperId: job['helperId'] ?? '',
          helperName: 'Helper',
          mode: 'complete',
        ),
      ),
    );

    if (result is Map && result['verified'] == true && context.mounted) {
      _navigateToPayment(context, job);
    }
  }

  void _navigateToPayment(BuildContext context, Map<String, dynamic> job) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final seekerId = authService.user?.uid ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UPIPaymentScreen(
          jobId: job['id'],
          jobTitle: job['title'] ?? 'Job',
          amount: (job['amount'] as num?)?.toDouble() ?? 0,
          helperId: job['helperId'] ?? '',
          helperName: job['helperName'] ?? 'Helper',
          seekerId: seekerId,
        ),
      ),
    );
  }

  void _showSessionDetails(
    BuildContext context,
    Map<String, dynamic> job,
    Map<String, dynamic>? profile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final seekerName = profile?['name'] ?? "User";
        final seekerAvatar = profile?['profilePicture'] ?? "";
        final bio = profile?['bio'] ?? "No bio available.";
        final seekerPhone = profile?['phoneNumber'] ?? "Not provided";
        final seekerEmail = profile?['email'] ?? "Not provided";

        // Date & Time Formatting
        String dateStr = "Date TBA";
        if (job['date'] != null) {
          try {
            dateStr = DateFormat(
              'EEE, d MMM',
            ).format(DateTime.parse(job['date']));
          } catch (_) {}
        }
        final timeStr = job['time'] ?? "Time TBA";

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Session Details",
                            style: GoogleFonts.plusJakartaSans(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Job Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job['title'] ?? "Untitled Job",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "₹${job['price']}",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF10B981),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Date & Time Row
                            Row(
                              children: [
                                _detailItem(Icons.calendar_today, dateStr),
                                const SizedBox(width: 16),
                                _detailItem(Icons.access_time, timeStr),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              job['description'] ?? "No description.",
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const Divider(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF3B82F6),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job['address'] ??
                                            (job['latitude'] != null
                                                ? "Location: ${job['latitude'].toStringAsFixed(4)}, ${job['longitude'].toStringAsFixed(4)}"
                                                : "Location not specified"),
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (job['latitude'] != null &&
                                          job['longitude'] != null)
                                        InkWell(
                                          onTap: () async {
                                            final lat = job['latitude'];
                                            final lng = job['longitude'];
                                            final uri = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                            );
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            }
                                          },
                                          child: Text(
                                            "View on Map",
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF3B82F6),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
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
                      const SizedBox(height: 32),
                      // User Info
                      Text(
                        widget.isSeeker ? "Helper Info" : "Seeker Info",
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CachedNetworkAvatar(
                                  imageUrl: seekerAvatar,
                                  radius: 30,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        seekerName,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.isSeeker
                                            ? "Assigned Helper"
                                            : "Job Poster",
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            // Contact Items
                            _contactItem(Icons.phone_outlined, seekerPhone),
                            const SizedBox(height: 12),
                            _contactItem(Icons.email_outlined, seekerEmail),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Bio",
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          bio,
                          style: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class JobSessionTimer extends StatefulWidget {
  final DateTime startTime;

  const JobSessionTimer({super.key, required this.startTime});

  @override
  State<JobSessionTimer> createState() => _JobSessionTimerState();
}

class _JobSessionTimerState extends State<JobSessionTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateDuration(null); // Initial update
    _timer = Timer.periodic(const Duration(seconds: 1), _updateDuration);
  }

  void _updateDuration(_) {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _duration = now.difference(widget.startTime);
        if (_duration.isNegative) _duration = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));

    // Modern Digital Clock Style
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _buildDigit(hours),
            _buildSeparator(),
            _buildDigit(minutes),
            _buildSeparator(),
            _buildDigit(seconds, isHighlight: true),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "SESSION DURATION",
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDigit(String value, {bool isHighlight = false}) {
    return Text(
      value,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: isHighlight
            ? const Color(0xFF3B82F6)
            : Colors.white, // Blue highlight for seconds
        shadows: [
          BoxShadow(
            color: (isHighlight ? const Color(0xFF3B82F6) : Colors.white)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        ":",
        style: GoogleFonts.jetBrainsMono(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: Colors.white24,
        ),
      ),
    );
  }
}

class _QRCodeBottomSheet extends StatefulWidget {
  final String jobId;
  final bool isCompletion;
  final double amount;

  const _QRCodeBottomSheet({
    required this.jobId,
    this.isCompletion = false,
    required this.amount,
  });

  @override
  State<_QRCodeBottomSheet> createState() => _QRCodeBottomSheetState();
}

class _QRCodeBottomSheetState extends State<_QRCodeBottomSheet> {
  String? _qrData;
  String? _error;
  bool _isLoading = true;
  Map<String, dynamic>? _helperProfile;

  // Timer
  Timer? _countdownTimer;
  Duration _remaining = const Duration(minutes: 5);
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final jobService = Provider.of<JobService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      final user = authService.user;

      if (user == null) throw Exception('Not logged in');

      // Fetch helper profile
      final profile = await userService.getUserProfile(user.uid);

      // Generate unique token on backend
      final token = widget.isCompletion
          ? await jobService.generateCompletionToken(widget.jobId)
          : await jobService.generateVerificationToken(widget.jobId);

      final now = DateTime.now();
      final expiry = now.add(const Duration(minutes: 5));

      // Build JSON payload for QR
      final qrPayload = jsonEncode({
        'token': token,
        'jobId': widget.jobId,
        'amount': widget.amount,
        'helperId': user.uid,
        'helperName': profile?['name'] ?? 'Unknown',
        'helperPhone': profile?['phoneNumber'] ?? 'N/A',
        'helperEmail': profile?['email'] ?? 'N/A',
        'helperSkills':
            (profile?['skills'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .join(', ') ??
            'N/A',
        'expiresAt': expiry.toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _qrData = qrPayload;
          _helperProfile = profile;
          _expiresAt = expiry;
          _remaining = const Duration(minutes: 5);
          _isLoading = false;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      if (_expiresAt != null && now.isBefore(_expiresAt!)) {
        setState(() {
          _remaining = _expiresAt!.difference(now);
        });
      } else {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.isCompletion
                  ? "Completion QR Code"
                  : "Verification QR Code",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isCompletion
                  ? "Ask the seeker to scan this code to complete the job."
                  : "Ask the seeker to scan this code to start the job.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading) ...[
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Generating secure code..."),
              const SizedBox(height: 40),
            ] else if (_error != null) ...[
              const SizedBox(height: 20),
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 12),
              Text(
                "Error: $_error",
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generateQR,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ] else ...[
              // Helper Info Card
              if (_helperProfile != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          (_helperProfile?['name'] as String? ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _helperProfile?['name'] ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _helperProfile?['phoneNumber'] ?? 'N/A',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user,
                        color: AppTheme.growthGreen,
                        size: 24,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1E293B),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Countdown Timer
              _remaining > Duration.zero
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _remaining.inSeconds <= 60
                              ? [
                                  Colors.red.withValues(alpha: 0.15),
                                  Colors.orange.withValues(alpha: 0.1),
                                ]
                              : [
                                  Colors.amber.withValues(alpha: 0.12),
                                  Colors.orange.withValues(alpha: 0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _remaining.inSeconds <= 60
                              ? Colors.red.withValues(alpha: 0.4)
                              : Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _remaining.inSeconds <= 60
                                ? Colors.red
                                : Colors.amber[800],
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Expires in",
                              style: GoogleFonts.inter(
                                color: _remaining.inSeconds <= 60
                                    ? Colors.red[700]
                                    : Colors.amber[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _remaining.inSeconds <= 60
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatDuration(_remaining),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _remaining.inSeconds <= 60
                                    ? Colors.red
                                    : Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.timer_off,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Code expired",
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _generateQR,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Generate New Code"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
