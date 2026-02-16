import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/job_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String category = 'Moving';
  double price = 20.0;

  final List<String> categories = [
    'Moving',
    'Cleaning',
    'Tech Support',
    'Tutoring',
    'Delivery',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Job"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator for "60-second flow"
              LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.growthGreen,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "What do you need help with?",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Job Title
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Job Title (e.g., Move a couch)",
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter a title' : null,
                onSaved: (val) => title = val!,
              ),
              const SizedBox(height: 20),

              // 2. Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => category = val!),
              ),
              const SizedBox(height: 20),

              // 3. Price Slider
              Text(
                "Your Offer: ₹${price.round()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Slider(
                value: price,
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: AppTheme.growthGreen,
                label: "₹${price.round()}",
                onChanged: (val) => setState(() => price = val),
              ),
              const Text(
                "Suggested: ₹150 - ₹250 based on similar jobs",
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // Get Current User
                      final user = Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).user;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please login to post a job"),
                          ),
                        );
                        return;
                      }

                      final jobData = {
                        'title': title,
                        'category': category,
                        'price': price,
                        'description': 'No description provided',
                        'posterId': user.uid, // Valid Poster ID
                        'posterName': user.displayName ?? 'Unknown',
                      };

                      try {
                        await Provider.of<JobService>(
                          context,
                          listen: false,
                        ).createJob(jobData);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Job Posted Successfully!"),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coinYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Post Job Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
