import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freelancer/features/jobs/screens/select_job_location_screen.dart';
import 'package:freelancer/features/search/screens/seeker_finding_helpers_screen.dart';
import 'package:freelancer/features/jobs/screens/job_success_screen.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _helperCountController = TextEditingController(
    text: '1',
  );
  bool _isLoading = false;
  bool _isHourly = true;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LatLng? _selectedLocation;

  Future<void> _postTask() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showError('Please enter a price');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_categoryController.text.trim().isEmpty) {
        _showError('Please select or type a category');
        setState(() => _isLoading = false);
        return;
      }

      String finalCategory = _categoryController.text.trim();

      await jobService.createJob({
        'title': '$finalCategory Task',
        'description': _descriptionController.text.trim(),
        'category': finalCategory,
        'price': double.parse(_priceController.text),
        'priceType': _isHourly ? 'hourly' : 'fixed',
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': _selectedTime.format(context),
        'posterId': authService.user!.uid,
        'helpersNeeded': int.tryParse(_helperCountController.text) ?? 1,
        if (_selectedLocation != null) ...{
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
      });

      if (mounted) {
        // Navigate to finding helpers animation
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeekerFindingHelpersScreen()),
        );

        // Simulate search delay then go to success
        await Future.delayed(const Duration(seconds: 4));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const JobSuccessScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to post task: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _helperCountController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Task",
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(4.w),
              child: LinearProgressIndicator(
                value: 0.3,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryBlue,
              ),
            ),

            SizedBox(height: 24.h),

            // Category
            Text(
              "Category",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            SizedBox(height: 12.h),

            // Main Category Input
            TextField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                // Update UI to check if any chip matches
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "E.g. Moving, Cleaning, Gardening...",
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Quick Select Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryPill(
                    icon: Icons.local_shipping,
                    label: "Moving",
                    isSelected:
                        _categoryController.text.toLowerCase() == "moving",
                    onTap: () {
                      _categoryController.text = "Moving";
                      setState(() {});
                    },
                  ),
                  SizedBox(width: 8.w),
                  _CategoryPill(
                    icon: Icons.cleaning_services,
                    label: "Cleaning",
                    isSelected:
                        _categoryController.text.toLowerCase() == "cleaning",
                    onTap: () {
                      _categoryController.text = "Cleaning";
                      setState(() {});
                    },
                  ),
                  SizedBox(width: 8.w),
                  _CategoryPill(
                    icon: Icons.grass,
                    label: "Yard Work",
                    isSelected:
                        _categoryController.text.toLowerCase() == "yard work",
                    onTap: () {
                      _categoryController.text = "Yard Work";
                      setState(() {});
                    },
                  ),
                  SizedBox(width: 8.w),
                  _CategoryPill(
                    icon: Icons.computer,
                    label: "Tech Support",
                    isSelected:
                        _categoryController.text.toLowerCase() ==
                        "tech support",
                    onTap: () {
                      _categoryController.text = "Tech Support";
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Description
            Text(
              "Description",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            SizedBox(height: 12.h),

            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    "What do you need help with? Be specific about heavy lifting, equipment needed, etc.",
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            const Wrap(
              spacing: 8,
              children: [
                _QuickTagButton(label: "+ Heavy Lifting"),
                _QuickTagButton(label: "+ Vehicle Required"),
              ],
            ),

            SizedBox(height: 24.h),

            // When?
            Text(
              "When?",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Show date picker
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Show time picker
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Helpers Needed
            Text(
              "Helpers Needed",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Number of helpers",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          int current =
                              int.tryParse(_helperCountController.text) ?? 1;
                          if (current > 1) {
                            setState(() {
                              _helperCountController.text = (current - 1)
                                  .toString();
                            });
                          }
                        },
                        icon: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.w),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 20.sp,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      Container(
                        width: 40.w,
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _helperCountController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          int current =
                              int.tryParse(_helperCountController.text) ?? 1;
                          if (current < 99) {
                            setState(() {
                              _helperCountController.text = (current + 1)
                                  .toString();
                            });
                          }
                        },
                        icon: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(6.w),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Your Offer
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Your Offer",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHourly = true;
                    });
                  },
                  child: _ToggleChip(label: "Hourly", isSelected: _isHourly),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHourly = false;
                    });
                  },
                  child: _ToggleChip(label: "Fixed", isSelected: !_isHourly),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    "₹",
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                suffixText: _isHourly ? "/hr" : "",
                suffixStyle: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            Text(
              "Est. Total: ₹50 - ₹75 (2-3 hrs)",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),

            SizedBox(height: 40.h),

            // Post Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_selectedLocation == null) {
                          // Navigate to location picker first
                          final LatLng? location = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SelectJobLocationScreen(),
                            ),
                          );
                          if (location != null) {
                            setState(() {
                              _selectedLocation = location;
                            });
                            // After selecting location, post the task
                            _postTask();
                          }
                        } else {
                          // Location already selected, post directly
                          _postTask();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedLocation == null
                                ? "Next: Select Location"
                                : "Post Task Now",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward, size: 20.sp),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(24.w),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTagButton extends StatelessWidget {
  final String label;

  const _QuickTagButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Add tag to description
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14.sp),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _ToggleChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
