import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isSeeker;
  const ProfileSetupScreen({super.key, required this.isSeeker});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String bio = '';
  List<String> selectedSkills = [];

  // Dummy skills for MVP
  final List<String> availableSkills = [
    'Moving Help',
    'Cleaning',
    'Tutoring',
    'Tech Support',
    'Event Staff',
    'Delivery',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSeeker ? 'Complete Your Profile' : 'Become a Helper',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 50.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        radius: 18,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),

              // Name
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter your name' : null,
                onSaved: (val) => name = val!,
              ),
              SizedBox(height: 16.h),

              // Bio
              TextFormField(
                decoration: InputDecoration(
                  labelText: widget.isSeeker ? 'About You' : 'Why hire you?',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onSaved: (val) => bio = val ?? '',
              ),
              SizedBox(height: 24.h),

              // Skills (Helper Only)
              if (!widget.isSeeker) ...[
                Text(
                  'Your Skills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 32.h),

                SizedBox(height: 32.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSkills.map((skill) {
                    final isSelected = selectedSkills.contains(skill);
                    return ChoiceChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: AppTheme.growthGreen.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.growthGreen : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSkills.add(skill);
                          } else {
                            selectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 30.h),
              ],

              // Submit
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final firestoreService = Provider.of<FirestoreService>(
                      context,
                      listen: false,
                    );

                    if (authService.user != null) {
                      final profileData = {
                        'name': name,
                        'bio': bio,
                        'role': widget.isSeeker ? 'seeker' : 'helper',
                        'skills': selectedSkills,
                        'completedProfile': true,
                      };

                      firestoreService.saveUserProfile(
                        authService.user!.uid,
                        profileData,
                      );

                      // Navigate to Home
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
