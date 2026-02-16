import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/auth_service.dart';

class RateHelperScreen extends StatefulWidget {
  final String helperId;
  final String jobId;
  final String helperName;

  const RateHelperScreen({
    super.key,
    required this.helperId,
    required this.jobId,
    required this.helperName,
  });

  @override
  State<RateHelperScreen> createState() => _RateHelperScreenState();
}

class _RateHelperScreenState extends State<RateHelperScreen> {
  int _overallRating = 0;
  double _communication = 4.0;
  double _punctuality = 4.0;
  double _quality = 4.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;

  // Selected tags
  final Set<String> _selectedTags = {};

  // Available tags
  final List<String> _availableTags = [
    "😊 Friendly",
    "💪 Hard working",
    "⚡ Fast",
    "👍 Professional",
    "👌 Punctual",
    "🧠 Skilled",
  ];

  Future<void> _submitReview() async {
    setState(() => _isLoading = true);
    try {
      final ratingService = Provider.of<RatingService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      await ratingService.submitRating(
        helperId: widget.helperId,
        seekerId: authService.user!.uid,
        jobId: widget.jobId,
        overallRating: _overallRating,
        communication: _communication,
        punctuality: _punctuality,
        quality: _quality,
        feedback: _feedbackController.text.trim(),
        tags: _selectedTags.toList(),
      );

      if (mounted) {
        // Navigate back to home/dashboard after successful review
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          "Rate Your Helper",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Helper Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CachedNetworkAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey.shade200,
                          fallbackIconColor: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.helperName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Helper",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Overall Rating
                  const Center(
                    child: Text(
                      "How was your experience?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _overallRating = index + 1),
                        child: Icon(
                          index < _overallRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 48,
                          color: const Color(0xFFFBBF24),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      _overallRating > 0
                          ? _getRatingText(_overallRating)
                          : "Tap to rate",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Detailed Ratings
                  const Text(
                    "Rate Specific Areas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  _RatingSlider(
                    icon: Icons.chat_bubble_outline,
                    label: "Communication",
                    value: _communication,
                    onChanged: (value) =>
                        setState(() => _communication = value),
                  ),

                  const SizedBox(height: 16),

                  _RatingSlider(
                    icon: Icons.access_time,
                    label: "Punctuality",
                    value: _punctuality,
                    onChanged: (value) => setState(() => _punctuality = value),
                  ),

                  const SizedBox(height: 16),

                  _RatingSlider(
                    icon: Icons.star_outline,
                    label: "Quality of Work",
                    value: _quality,
                    onChanged: (value) => setState(() => _quality = value),
                  ),

                  const SizedBox(height: 32),

                  // Feedback
                  const Text(
                    "Additional Feedback (Optional)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: "Share more about your experience...",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: _QuickTag(label: tag, isSelected: isSelected),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Add Photo
                  const Text(
                    "Add Photo Proof (Optional)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap to add photo",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _overallRating > 0 && !_isLoading
                      ? _submitReview
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Submit Review",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check, size: 20),
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Poor";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      case 4:
        return "Great";
      case 5:
        return "Excellent!";
      default:
        return "";
    }
  }
}

class _RatingSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryBlue,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: AppTheme.primaryBlue,
            overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 8,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _QuickTag extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _QuickTag({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
        ),
      ),
    );
  }
}
