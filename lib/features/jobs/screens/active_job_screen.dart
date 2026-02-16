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
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class ActiveJobScreen extends StatefulWidget {
  final bool isSeeker;
  final String? initialJobId;

  const ActiveJobScreen({super.key, required this.isSeeker, this.initialJobId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Timer is managed by stream listener logic below
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocalTimer(DateTime start) {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        if (now.isAfter(start)) {
          _duration = now.difference(start);
        } else {
          _duration = Duration.zero;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: jobService.getActiveJobsForUser(
        userId,
        isSeeker: widget.isSeeker,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF101622),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return _buildNoActiveJob(context);
        }

        // Use the first active job or filter by initialJobId match
        final job = (widget.initialJobId != null)
            ? jobs.firstWhere(
                (j) => j['id'] == widget.initialJobId,
                orElse: () => jobs.first,
              )
            : jobs.first;

        final jobId = job['id'];
        final status = job['status'];
        final startedAtTimestamp = job['startedAt'] as Timestamp?;
        final helperName = "Student Helper"; // Ideally fetch user profile
        final helperAvatar = "https://randomuser.me/api/portraits/men/32.jpg";

        // Logic to sync timer
        if (status == 'in_progress' && startedAtTimestamp != null) {
          _startLocalTimer(startedAtTimestamp.toDate());
        } else if (status == 'assigned') {
          _duration = Duration.zero;

          // Auto-show QR if requested by Seeker
          final startRequested = job['startRequested'] == true;
          debugPrint(
            "ActiveJobScreen: status=assigned, startRequested=$startRequested, isSeeker=${widget.isSeeker}, hasAutoShown=$_hasAutoShownQR",
          );

          if (!widget.isSeeker && startRequested && !_hasAutoShownQR) {
            debugPrint("ActiveJobScreen: Triggering auto-show QR");
            _hasAutoShownQR = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                debugPrint("ActiveJobScreen: Calling _showStartJobQR");
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
        );
      },
    );
  }

  Widget _buildNoActiveJob(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              "No Active Jobs",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
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
  }) {
    final darkBg = const Color(0xFF101622);
    final cardBg = const Color(0xFF1A2232);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Active Job",
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Map Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, darkBg],
                stops: const [0.7, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.darken,
              child: Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCfPC67zM3hMs4qAmcfFdtth5Ykw6D9vXlsa_lGFkFdMZngWrqFaDtRdRs7vmPh7uqe2_ecg1h_J8JuQRNj0J4ftQKZ3CuZjsGPU417u-BZZ4SqAmIgCqdboWDnVlxf7j6uejM1o8hZC3sQfMM9Nxd9NOFvtU5E19AeEvvqsm4GHtNJdkJUx756RohhEqvdOniAnedH2-JRNRVpuY7BHDrFKgaX7iu-gcilyvTrzVQ-nz8lUvXyMu8N5a97riQ1pp9zopT9uaJSEfs",
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Helper Avatar
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: darkBg.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: CachedNetworkAvatar(
                      imageUrl: helperAvatar,
                      radius: 40,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      helperName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(color: darkBg),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status == 'assigned'
                            ? (job['startRequested'] == true
                                  ? "Start Requested!"
                                  : "Helper assigned")
                            : "Job in progress",
                        style: GoogleFonts.plusJakartaSans(
                          color:
                              status == 'assigned' &&
                                  job['startRequested'] == true
                              ? Colors.greenAccent
                              : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status == 'assigned'
                            ? (job['startRequested'] == true
                                  ? "Opening QR Code..."
                                  : "Waiting for seeker to start.")
                            : "Timer is tracking the session.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Timer Row
                      _buildTimerRow(
                        status == 'assigned' ? Duration.zero : _duration,
                      ),

                      const SizedBox(height: 32),

                      // Start Button if assigned & is helper (but this is ActiveJobScreen usually shared)
                      // For Seeker, they usually just watch.
                      // For Helper, they start.
                      // If Seeker checks this screen and status is 'assigned', they just see "Waiting".
                      // The button below "End Task" is for finishing.
                      _buildButtons(context, status, job),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // State variable to track if QR was already auto-shown
  bool _hasAutoShownQR = false;

  @override
  void didUpdateWidget(ActiveJobScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset flag if job ID changes (though unlikely for this screen usage)
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
    if (status == 'assigned') {
      return Column(
        children: [
          _buildActionButton(
            icon: Icons.chat_bubble,
            label: widget.isSeeker ? "Chat with Helper" : "Chat with Seeker",
            isPrimary: false,
            onTap: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              final chatService = Provider.of<ChatService>(
                context,
                listen: false,
              );
              final currentUserId = authService.user?.uid;

              if (currentUserId == null) return;

              final otherUserId = widget.isSeeker
                  ? job['helperId']
                  : job['seekerId'];
              final otherUserName = widget.isSeeker
                  ? "Student Helper"
                  : "Job Provider";

              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Opening chat..."),
                    duration: Duration(seconds: 1),
                  ),
                );

                final chatId = await chatService.createChat(
                  otherUserId,
                  currentUserId,
                  checkFriendship:
                      false, // In a job context, they should be able to chat
                );

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not open chat: $e")),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          if (!widget.isSeeker) ...[
            _buildActionButton(
              icon: Icons.qr_code,
              label: "Show Verification QR",
              subtitle: "For Seeker to scan",
              isPrimary: true,
              onTap: () {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                _showStartJobQR(context, jobId, amount);
              },
            ),
          ] else ...[
            _buildActionButton(
              icon: Icons.play_arrow,
              label: "Start Job",
              subtitle: "Scan Helper's QR",
              isPrimary: true,
              onTap: () async {
                // 1. Request Job Start (triggers Helper's QR)
                try {
                  await Provider.of<JobService>(
                    context,
                    listen: false,
                  ).requestJobStart(jobId);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to request start: $e")),
                    );
                  }
                  debugPrint("Error requesting start: $e");
                  // Do not proceed to scanner if request failed, or maybe ask retry?
                  // For now, let's stop to ensure they know it failed.
                  return;
                }
                // 2. Open Scanner
                if (context.mounted) _navigateToScanner(context, jobId);
              },
            ),
          ],
        ],
      );
    }

    // In-progress: role-specific end-job buttons
    if (status == 'in_progress') {
      return Column(
        children: [
          _buildActionButton(
            icon: Icons.chat_bubble,
            label: widget.isSeeker ? "Chat with Helper" : "Chat with Seeker",
            isPrimary: false,
            onTap: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              final chatService = Provider.of<ChatService>(
                context,
                listen: false,
              );
              final currentUserId = authService.user?.uid;
              if (currentUserId == null) return;
              final otherUserId = widget.isSeeker
                  ? job['helperId']
                  : job['seekerId'];
              final otherUserName = widget.isSeeker
                  ? "Student Helper"
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
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not open chat: $e")),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          if (!widget.isSeeker) ...[
            // Helper: Show completion QR for seeker to scan
            _buildActionButton(
              icon: Icons.qr_code,
              label: "Show Completion QR",
              subtitle: "For Seeker to scan & pay",
              isPrimary: true,
              onTap: () {
                final double amount = (job['price'] as num?)?.toDouble() ?? 0.0;
                _showCompletionQR(context, jobId, amount);
              },
            ),
          ] else ...[
            // Seeker: Scan helper's completion QR then pay
            _buildActionButton(
              icon: Icons.payment,
              label: "End Job & Pay",
              subtitle: "Scan Helper's QR to complete",
              isPrimary: true,
              onTap: () => _navigateToCompletionScanner(context, job),
            ),
          ],
        ],
      );
    }

    // payment_pending: show processing state
    if (status == 'payment_pending') {
      return Column(
        children: [
          _buildActionButton(
            icon: Icons.hourglass_top,
            label: "Payment Processing",
            subtitle: "Completing job payment...",
            isPrimary: true,
            onTap: () {
              if (widget.isSeeker) {
                // Navigate to payment screen
                _navigateToPayment(context, job);
              }
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showStartJobQR(BuildContext context, String jobId, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _QRCodeBottomSheet(jobId: jobId, amount: amount),
    );
  }

  Future<void> _navigateToScanner(BuildContext context, String jobId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobVerificationScannerScreen(
          jobId: jobId,
          helperId: "helper",
          helperName: "Helper",
          mode: 'start',
        ),
      ),
    );

    if (result == true) {
      // StreamBuilder will update UI automatically
    }
  }

  /// Show completion QR for the helper (mirrors start QR)
  void _showCompletionQR(BuildContext context, String jobId, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _QRCodeBottomSheet(
          jobId: jobId,
          isCompletion: true,
          amount: amount,
        );
      },
    );
  }

  /// Navigate seeker to the completion scanner, then to payment
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

  /// Navigate seeker to UPI payment screen
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

  Widget _buildTimerRow(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimerItem(hours, "HOURS"),
        _buildTimerSeparator(),
        _buildTimerItem(minutes, "MINUTES"),
        _buildTimerSeparator(),
        _buildTimerItem(seconds, "SECONDS", isBlue: true),
      ],
    );
  }

  Widget _buildTimerItem(String value, String label, {bool isBlue = false}) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isBlue ? const Color(0xFF1E3A8A) : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: isBlue ? const Color(0xFF3B82F6) : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBlue ? const Color(0xFF3B82F6) : Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSeparator() {
    return Container(
      height: 70,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ":",
        style: GoogleFonts.inter(
          color: Colors.grey[600],
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subtitle,
    int? count,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryBlue : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(30),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPrimary) ...[
              const Icon(Icons.qr_code, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ] else ...[
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$count",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ],
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
                      Icon(
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
