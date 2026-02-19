import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/job_service.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages =
      []; // {role: 'user'|'ai', text: '...'}
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    _messages.add({
      'role': 'ai',
      'text':
          'Hello! I am your Smart Financial Assistant. 🤖\n\nI can analyze your spending, check your budget, and give advice. How can I help you today?',
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception("User not logged in");

      final financeService = Provider.of<FinanceService>(
        context,
        listen: false,
      );
      final userService = Provider.of<UserService>(context, listen: false);
      final jobService = Provider.of<JobService>(context, listen: false);

      // Fetch context data
      final transactions = await financeService.getTransactions(user.uid).first;
      final budget = await financeService.getBudgetStream(user.uid).first;

      // --- NEW: Fetch App Data ---

      final userProfile = await userService.getUserProfile(user.uid);
      final activeJobs = await jobService
          .getActiveJobsForUser(
            user.uid,
            isSeeker: userProfile?['role'] == 'seeker',
          )
          .first;
      final applications = await jobService
          .getHelperApplications(user.uid)
          .first;

      String appData = "User Profile:\n";
      if (userProfile != null) {
        appData += "- Name: ${userProfile['name']}\n";
        appData += "- Role: ${userProfile['role']}\n";
        appData += "- Wallet Balance: ₹${userProfile['walletBalance']}\n";
        appData += "- Total Earnings: ₹${userProfile['totalEarnings']}\n";
        appData += "- Gigs Completed: ${userProfile['gigsCompleted']}\n";
        appData += "- Points: ${userProfile['points']}\n";
      }

      appData += "\nWork Status:\n";
      appData +=
          "- Active Jobs: ${activeJobs.length} (${activeJobs.map((j) => j['title']).join(', ')})\n";
      appData += "- Pending Applications: ${applications.length}\n";
      // ---------------------------

      // Extract last 5 messages for history (excluding current user message)
      // _messages contains the current user message at the end.
      // We want to skip that one.
      final history = _messages
          .where((m) => m['role'] != 'system')
          .take(_messages.length - 1)
          .toList();

      List<Map<String, String>> recentHistory = [];
      if (history.length > 5) {
        recentHistory = history.sublist(history.length - 5);
      } else {
        recentHistory = history;
      }

      // Get AI Response
      final response = await financeService.getAIAdvice(
        transactions,
        budget: budget,
        userMessage: text,
        history: recentHistory,
        appData: appData, // Pass aggregated data
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'Sorry, I encountered an error: $e',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Financial Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottomRight: isUser
                            ? Radius.zero
                            : const Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzing data...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask: "Can I spend 500?"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
