import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer/features/jobs/screens/hired_success_screen.dart';
import 'package:freelancer/features/chat/screens/chat_screen.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/profile/screens/helper_profile_screen.dart';
import 'package:freelancer/features/jobs/screens/job_verification_scanner_screen.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/features/jobs/screens/upi_payment_screen.dart';

class JobApplicationsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicationsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  bool _isProcessing = false;

  Future<void> _acceptApplication(
    String applicationId,
    String helperId,
    String helperName,
    String helperImage,
    String helperEmail,
    String helperPhoneNumber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Application'),
        content: Text(
          'Accept $helperName for this job? All other applications will be rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    if (!mounted) return;

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      await jobService.acceptApplication(widget.jobId, applicationId, helperId);

      // Notify the helper that their application was accepted
      await notificationService.createNotification(
        userId: helperId,
        title: 'Application Accepted! 🎉',
        subtitle: 'You have been assigned to "${widget.jobTitle}"',
        type: 'job',
        relatedId: widget.jobId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$helperName has been assigned to this job!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        // Navigate to Success Screen instead of just popping
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HiredSuccessScreen(
              helperName: helperName,
              helperImage: helperImage,
              helperEmail: helperEmail,
              helperPhoneNumber: helperPhoneNumber,
              jobId: widget.jobId,
              onGoToChat: () async {
                try {
                  final chatService = Provider.of<ChatService>(
                    context,
                    listen: false,
                  );
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  // Create/Get chat channel
                  final chatId = await chatService.createChat(
                    helperId,
                    authService.user!.uid,
                    checkFriendship: false,
                  );
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId,
                          otherUserName: helperName,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              onViewTask: () {
                Navigator.pop(context); // Close success screen
                // Stay on Apps screen (now assigned) or pop?
                // Depending on user preference. Let's stay to show "Processed" list.
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectApplication(
    String applicationId,
    String helperName,
    String helperId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Text('Reject $helperName\'s application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    if (!mounted) return;

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );

      await jobService.rejectApplication(applicationId);

      // Notify the helper that their application was rejected
      await notificationService.createNotification(
        userId: helperId,
        title: 'Application Update',
        subtitle: 'Your application for "${widget.jobTitle}" was not selected',
        type: 'job',
        relatedId: widget.jobId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobService = Provider.of<JobService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final seekerId = authService.user?.uid ?? '';

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applications', style: TextStyle(fontSize: 16)),
            Text(
              widget.jobTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: jobService.getJobApplications(widget.jobId, seekerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                // Log the error for debugging
                debugPrint('Error loading applications: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load applications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString().contains(
                                'requires an index',
                              )
                              ? 'Setting up database... Please wait a few minutes and try again.'
                              : 'Please check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final applications = snapshot.data ?? [];
              final pendingApplications = applications
                  .where((app) => app['status'] == 'pending')
                  .toList();

              if (applications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No applications yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Helpers will apply soon',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pendingApplications.isNotEmpty) ...[
                    Text(
                      'Pending (${pendingApplications.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pendingApplications.map(
                      (app) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ApplicationCard(
                          application: app,
                          onAccept: (name, image, email, phoneNumber) =>
                              _acceptApplication(
                                app['id'],
                                app['helperId'],
                                name,
                                image,
                                email,
                                phoneNumber,
                              ),
                          onReject: () => _rejectApplication(
                            app['id'],
                            '', // Will be fetched from helper profile
                            app['helperId'],
                          ),
                          onViewProfile: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HelperProfileScreen(
                                  helperId: app['helperId'],
                                  bypassPrivacy: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (applications.any(
                    (app) => app['status'] == 'accepted',
                  )) ...[
                    const Text(
                      'Processed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...applications
                        .where((app) => app['status'] == 'accepted')
                        .map(
                          (app) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProcessedApplicationCard(application: app),
                          ),
                        ),
                  ],
                ],
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final void Function(
    String name,
    String image,
    String email,
    String phoneNumber,
  )
  onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _ApplicationCard({
    required this.application,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final helperId = application['helperId'] as String;

    return FutureBuilder<Map<String, dynamic>?>(
      future: userService.getUserProfile(helperId),
      builder: (context, snapshot) {
        final helper = snapshot.data;
        if (helper == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final name = helper?['name'] ?? 'Unknown Helper';
        final imageUrl = helper?['profileImage'] ?? '';
        final rating = (helper?['rating'] ?? 0.0).toDouble();
        final reviewCount = helper?['reviewCount'] ?? 0;
        final skills =
            (helper?['skills'] as List?)?.map((s) => s.toString()).toList() ??
            [];

        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: onViewProfile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isProfileHighlighted(helper ?? {})
                    ? const Color(0xFFFFD700)
                    : colorScheme.outlineVariant,
                width: _isProfileHighlighted(helper ?? {}) ? 2.0 : 1.0,
              ),
              boxShadow: _isProfileHighlighted(helper ?? {})
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkAvatar(
                      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                      radius: 24,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      fallbackIconColor: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (skills.isNotEmpty)
                            Text(
                              skills.take(2).join(" • "),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              Text(
                                " $rating ($reviewCount reviews)",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAccept(
                          name,
                          helper?['profileImage'] ?? '',
                          helper?['email'] ?? '',
                          helper?['phoneNumber'] ?? '',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isProfileHighlighted(Map<String, dynamic> helper) {
    final activePowerUps = helper['activePowerUps'] as Map<String, dynamic>?;
    if (activePowerUps == null) return false;

    if (activePowerUps.containsKey('Highlight Profile')) {
      final expiresAt = (activePowerUps['Highlight Profile'] as Timestamp)
          .toDate();
      return DateTime.now().isBefore(expiresAt);
    }
    return false;
  }
}

class _ProcessedApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ProcessedApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final helperId = application['helperId'] as String;
    final status = application['status'];
    final isAccepted = status == 'accepted';
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: userService.getUserProfile(helperId),
      builder: (context, snapshot) {
        final helper = snapshot.data;
        if (helper == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final name = helper?['name'] ?? 'Unknown Helper';
        final imageUrl = helper?['profileImage'] ?? '';
        final email = helper?['email'] ?? '';
        final phoneNumber = helper?['phoneNumber'] ?? '';

        final safetySettings =
            helper?['safetySettings'] as Map<String, dynamic>?;
        final blurContact = safetySettings?['blurContact'] ?? true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAccepted
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CachedNetworkAvatar(
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                    radius: 20,
                    backgroundColor: colorScheme.surfaceContainerLow,
                    fallbackIconColor: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              isAccepted ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: isAccepted
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAccepted ? 'Hired' : 'Rejected',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAccepted
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isAccepted)
                StreamBuilder<Map<String, dynamic>?>(
                  stream: Provider.of<JobService>(
                    context,
                    listen: false,
                  ).getJobStream(application['jobId']),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final job = jobSnapshot.data;
                    final jobStatus = job?['status'] ?? 'assigned';
                    final isJobStarted =
                        jobStatus == 'in_progress' ||
                        jobStatus == 'completed' ||
                        jobStatus == 'payment_pending';

                    final shouldBlur = blurContact && !isJobStarted;

                    final displayedPhone = shouldBlur
                        ? (phoneNumber.length > 4
                              ? '+91 ***** *${phoneNumber.substring(phoneNumber.length - 4)}'
                              : '******')
                        : phoneNumber;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        if (email
                            .isNotEmpty) // Email is usually less sensitive but let's show it.
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (phoneNumber.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                displayedPhone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (shouldBlur)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 16),
                        _buildAction(
                          context,
                          jobStatus,
                          application['jobId'],
                          helperId,
                          name,
                          job,
                          colorScheme,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAction(
    BuildContext context,
    String status,
    String jobId,
    String helperId,
    String helperName,
    Map<String, dynamic>? job,
    ColorScheme colorScheme,
  ) {
    if (status == 'completed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Job Completed'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: const Color(
              0xFF10B981,
            ).withValues(alpha: 0.2),
            disabledForegroundColor: const Color(0xFF10B981),
          ),
        ),
      );
    }

    if (status == 'payment_pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UPIPaymentScreen(
                  jobId: job?['id'],
                  jobTitle: job?['title'] ?? 'Job',
                  amount: (job?['price'] as num?)?.toDouble() ?? 0,
                  helperId: helperId,
                  helperName: helperName,
                  seekerId:
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).user?.uid ??
                      '',
                ),
              ),
            );
          },
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Complete Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            // Navigate to scanner to complete job
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobVerificationScannerScreen(
                  jobId: jobId,
                  helperId: helperId,
                  helperName: helperName,
                  mode: 'complete',
                ),
              ),
            );

            if (result is Map &&
                result['verified'] == true &&
                context.mounted) {
              // Proceed to payment
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UPIPaymentScreen(
                    jobId: job?['id'],
                    jobTitle: job?['title'] ?? 'Job',
                    amount: (job?['price'] as num?)?.toDouble() ?? 0,
                    helperId: helperId,
                    helperName: helperName,
                    seekerId:
                        Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).user?.uid ??
                        '',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.qr_code_scanner, size: 18), // Scan to complete
          label: const Text('End Job & Pay'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      );
    }

    // Default: assigned -> Start Job
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobVerificationScannerScreen(
                jobId: jobId,
                helperId: helperId,
                helperName: helperName,
                mode: 'start',
              ),
            ),
          );
        },
        icon: const Icon(Icons.qr_code_scanner, size: 18),
        label: const Text('Start Job'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
