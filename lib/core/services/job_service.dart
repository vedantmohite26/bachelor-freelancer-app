import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retry logic for transient Firestore errors
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }

  // Get all open jobs
  Stream<List<Map<String, dynamic>>> getOpenJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get jobs by category
  Stream<List<Map<String, dynamic>>> getJobsByCategory(String category) {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get job by ID
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    final doc = await _firestore.collection('jobs').doc(jobId).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  // Get job stream by ID
  Stream<Map<String, dynamic>?> getJobStream(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data()!, 'id': doc.id};
    });
  }

  // Create new job with validation
  Future<String> createJob(Map<String, dynamic> jobData) async {
    // Validate required fields
    if (!jobData.containsKey('title') || (jobData['title'] as String).isEmpty) {
      throw ArgumentError('Job title is required');
    }
    if (!jobData.containsKey('description') ||
        (jobData['description'] as String).isEmpty) {
      throw ArgumentError('Job description is required');
    }
    if (!jobData.containsKey('price') || (jobData['price'] as num) <= 0) {
      throw ArgumentError('Valid price is required');
    }
    if (!jobData.containsKey('posterId') ||
        (jobData['posterId'] as String).isEmpty) {
      throw ArgumentError('Poster ID is required');
    }

    // Sanitize inputs
    final sanitized = {
      ...jobData,
      'title': (jobData['title'] as String).trim(),
      'description': (jobData['description'] as String).trim(),
      'price': (jobData['price'] as num).toDouble(),
    };

    return _retryOperation(() async {
      final docRef = await _firestore.collection('jobs').add({
        ...sanitized,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'applications': 0,
      });
      return docRef.id;
    });
  }

  // Apply for job with validation and optimization
  Future<void> applyForJob(String jobId, String helperId) async {
    if (jobId.isEmpty || helperId.isEmpty) {
      throw ArgumentError('Job ID and Helper ID are required');
    }

    return _retryOperation(() async {
      final jobRef = _firestore.collection('jobs').doc(jobId);
      // Use deterministic ID to prevent duplicates without extra reads
      final applicationRef = _firestore
          .collection('applications')
          .doc('${jobId}_$helperId');

      await _firestore.runTransaction((transaction) async {
        // 1. Check if already applied (Read the specific doc)
        final applicationDoc = await transaction.get(applicationRef);
        if (applicationDoc.exists) {
          throw Exception('Already applied to this job');
        }

        // 2. Fetch Job to validate status and get posterId
        final jobDoc = await transaction.get(jobRef);
        if (!jobDoc.exists) throw Exception('Job not found');

        final jobData = jobDoc.data()!;
        if (jobData['status'] != 'open') throw Exception('Job is not open');

        final posterId = jobData['posterId'] as String;

        // 3. Create application
        transaction.set(applicationRef, {
          'jobId': jobId,
          'helperId': helperId,
          'seekerId': posterId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Increment application count
        transaction.update(jobRef, {'applications': FieldValue.increment(1)});
      });
    });
  }

  // Check if helper has applied to specific job (any status)
  Future<bool> hasAppliedToJob(String jobId, String helperId) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('helperId', isEqualTo: helperId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Get helper's all applications (for checking applied status)
  Stream<List<Map<String, dynamic>>> getAllHelperApplications(String helperId) {
    return _firestore
        .collection('applications')
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get helper's active applications (pending only)
  Stream<List<Map<String, dynamic>>> getHelperApplications(String helperId) {
    return _firestore
        .collection('applications')
        .where('helperId', isEqualTo: helperId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get helper's upcoming gigs (accepted jobs)
  Stream<List<Map<String, dynamic>>> getHelperUpcomingGigs(String helperId) {
    return _firestore
        .collection('jobs')
        .where('assignedHelperId', isEqualTo: helperId)
        .where(
          'status',
          whereIn: ['assigned', 'in_progress', 'payment_pending'],
        )
        .orderBy(
          'createdAt',
          descending: false,
        ) // Changed from date to createdAt for reliability
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Get helper's completed jobs (for resume)
  Future<List<Map<String, dynamic>>> getHelperCompletedJobs(
    String helperId,
  ) async {
    final snapshot = await _firestore
        .collection('jobs')
        .where('assignedHelperId', isEqualTo: helperId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete job and update earnings + transaction history
  Future<void> completeJob(
    String jobId,
    String helperId,
    double earnings,
    String jobTitle,
  ) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(helperId);

    // 1. Update Job Status
    batch.update(_firestore.collection('jobs').doc(jobId), {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update Helper Stats (Earnings & XP)
    batch.update(userRef, {
      'totalEarnings': FieldValue.increment(earnings),
      'walletBalance': FieldValue.increment(
        earnings,
      ), // Update spendable balance
      'todaysEarnings': FieldValue.increment(earnings),
      'gigsCompleted': FieldValue.increment(1),
      'points': FieldValue.increment(50), // 50 XP for completion
    });

    // 3. Create Transaction Record
    final txnRef = userRef.collection('transactions').doc();
    batch.set(txnRef, {
      'title': "Completed: $jobTitle",
      'amount': earnings,
      'isCoin': false,
      'type': 'job_payment',
      'timestamp': FieldValue.serverTimestamp(),
      'relatedJobId': jobId,
    });

    await batch.commit();
  }

  // "Slide to Accept" - Direct Claim logic
  Future<void> claimJob(String jobId, String helperId) async {
    return _retryOperation(() async {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(jobRef);

        if (!snapshot.exists) throw Exception("Job does not exist");

        final status = snapshot.data()?['status'];
        if (status != 'open') {
          throw Exception("Job is no longer open");
        }

        // Assign immediately
        transaction.update(jobRef, {
          'status': 'assigned',
          'assignedHelperId': helperId,
          'assignedAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }

  /// Get jobs posted by a specific user (seeker)
  Stream<List<Map<String, dynamic>>> getUserPostedJobs(String userId) {
    return _firestore
        .collection('jobs')
        .where('posterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Get all applications for a specific job (Seeker must provide their ID)
  Stream<List<Map<String, dynamic>>> getJobApplications(
    String jobId,
    String seekerId,
  ) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('seekerId', isEqualTo: seekerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Get real-time count of applications for a job (Seeker only)
  Stream<int> getApplicationCountStream(String jobId, String seekerId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('seekerId', isEqualTo: seekerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Accept an application and assign helper to job
  Future<void> acceptApplication(
    String jobId,
    String applicationId,
    String helperId,
  ) async {
    return _retryOperation(() async {
      final batch = _firestore.batch();

      // Update application status
      batch.update(_firestore.collection('applications').doc(applicationId), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update job status and assign helper
      batch.update(_firestore.collection('jobs').doc(jobId), {
        'status': 'assigned',
        'assignedHelperId': helperId,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // Reject all other applications for this job
      final otherApplications = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in otherApplications.docs) {
        if (doc.id != applicationId) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    });
  }

  /// Reject an application
  Future<void> rejectApplication(String applicationId) async {
    return _retryOperation(() async {
      await _firestore.collection('applications').doc(applicationId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cancel a job (only if not assigned)
  Future<void> cancelJob(String jobId) async {
    return _retryOperation(() async {
      final job = await _firestore.collection('jobs').doc(jobId).get();

      if (!job.exists) {
        throw Exception('Job not found');
      }

      final status = job.data()?['status'] as String?;
      if (status == 'assigned' || status == 'completed') {
        throw Exception('Cannot cancel job that is assigned or completed');
      }

      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get active jobs for user
  Stream<List<Map<String, dynamic>>> getActiveJobsForUser(
    String userId, {
    bool isSeeker = true,
  }) {
    // We check for both 'assigned' and 'in_progress'
    final field = isSeeker ? 'posterId' : 'assignedHelperId';
    return _firestore
        .collection('jobs')
        .where(field, isEqualTo: userId)
        .where(
          'status',
          whereIn: ['assigned', 'in_progress', 'payment_pending'],
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Start job (Transition to in_progress)
  Future<void> startJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // Generate Verification Token (expires in 5 minutes)
  Future<String> generateVerificationToken(String jobId) async {
    return _retryOperation(() async {
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final String secureToken = "VERIFY_${jobId.substring(0, 5)}_$random";

      await _firestore.collection('jobs').doc(jobId).update({
        'verificationToken': secureToken,
        'verificationTokenExpiresAt': DateTime.now().add(
          const Duration(minutes: 5),
        ),
      });
      return secureToken;
    });
  }

  // Request Job Start (Seeker triggers this)
  Future<void> requestJobStart(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'startRequested': true,
      'startRequestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Verify and Start Job (QR Code Scan with Token)
  Future<bool> verifyAndStartJob(String jobId, String scannedToken) async {
    return _retryOperation(() async {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) throw Exception('Job not found');

        final jobData = jobDoc.data()!;
        final status = jobData['status'] as String?;
        final storedToken = jobData['verificationToken'] as String?;
        final expiresAt = (jobData['verificationTokenExpiresAt'] as Timestamp?)
            ?.toDate();

        if (status == 'in_progress') return; // Already started

        if (status != 'assigned') {
          throw Exception('Job is not in "assigned" state.');
        }

        if (storedToken == null || storedToken != scannedToken) {
          throw Exception('Invalid QR Code.');
        }

        if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
          throw Exception(
            'QR Code has expired. Please ask helper to regenerate.',
          );
        }

        // checks pass, start the job
        transaction.update(jobRef, {
          'status': 'in_progress',
          'startedAt': FieldValue.serverTimestamp(),
          'verifiedStart': true,
          'verificationToken': FieldValue.delete(), // Clean up
          'verificationTokenExpiresAt': FieldValue.delete(),
          'startRequested': FieldValue.delete(), // Clean up
          'startRequestedAt': FieldValue.delete(),
        });
      });

      return true;
    });
  }

  // Generate Completion Token (unique per-job, expires in 5 minutes)
  Future<String> generateCompletionToken(String jobId) async {
    return _retryOperation(() async {
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final String secureToken = "COMPLETE_${jobId.substring(0, 5)}_$random";

      await _firestore.collection('jobs').doc(jobId).update({
        'completionToken': secureToken,
        'completionTokenExpiresAt': DateTime.now().add(
          const Duration(minutes: 5),
        ),
      });
      return secureToken;
    });
  }

  // Verify and Complete Job (QR Code Scan with Completion Token)
  // Transitions job to 'payment_pending' for payment processing
  Future<bool> verifyAndCompleteJob(String jobId, String scannedToken) async {
    return _retryOperation(() async {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) throw Exception('Job not found');

        final jobData = jobDoc.data()!;
        final status = jobData['status'] as String?;
        final storedToken = jobData['completionToken'] as String?;
        final expiresAt = (jobData['completionTokenExpiresAt'] as Timestamp?)
            ?.toDate();

        if (status == 'completed' || status == 'payment_pending') {
          return; // Already completed or pending payment
        }

        if (status != 'in_progress') {
          throw Exception('Job is not in progress.');
        }

        if (storedToken == null || storedToken != scannedToken) {
          throw Exception('Invalid completion QR Code.');
        }

        if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
          throw Exception(
            'QR Code has expired. Please ask helper to regenerate.',
          );
        }

        // All checks pass → transition to payment_pending
        transaction.update(jobRef, {
          'status': 'payment_pending',
          'paymentRequestedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    });
  }
}
