import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/document_verification_service.dart';
import 'package:freelancer/features/auth/screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  final bool isGoogleSignIn;

  const SignUpScreen({super.key, this.isGoogleSignIn = false});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = Basic Auth, 1 = Profile Details

  // State
  bool _isHelper = true; // true = Earn Money, false = Hire Help
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Step 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Step 2 Controllers
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];

  // Document Verification State
  File? _aadhaarFile;
  File? _panFile;
  bool _isAadhaarVerified = false;
  bool _isPanVerified = false;
  String? _aadhaarError;
  String? _panError;
  final DocumentVerificationService _verificationService =
      DocumentVerificationService();

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleSignIn) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _nameController.text = authService.user?.displayName ?? '';
      _emailController.text = authService.user?.email ?? '';
    }
  }

  void _nextStep() {
    // Validation Step 1
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    if (!widget.isGoogleSignIn && _passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    // Attempt to auto-fill university from email
    if (_universityController.text.isEmpty && email.contains('@')) {
      final domain = email.split('@')[1];
      if (domain.contains('edu') || domain.contains('ac.in')) {
        // Simple heuristic, can be improved
        _universityController.text = domain.split('.')[0].toUpperCase();
      }
    }

    setState(() => _currentStep = 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    setState(() => _currentStep = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickAndVerifyDocument(String type) async {
    // Show option to choose Image or PDF
    final isPdf = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Image (JPG/PNG)'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Upload PDF'),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (isPdf == null) return;

    File? file;
    if (isPdf) {
      // Pick PDF
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      } catch (e) {
        debugPrint('Error picking PDF: $e');
      }
    } else {
      // Pick Image
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          file = File(pickedFile.path);
        }
      } catch (e) {
        _showError('Error picking image: $e');
        return;
      }
    }

    if (file != null) {
      if (mounted) {
        setState(() {
          if (type == 'aadhaar') {
            _aadhaarFile = file;
            _aadhaarError = null; // Reset error
            _isAadhaarVerified = false;
          } else {
            _panFile = file;
            _panError = null; // Reset error
            _isPanVerified = false;
          }
          _isLoading = true;
        });
      }

      final result = await _verificationService.verifyDocument(file, type);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.isValid) {
            if (type == 'aadhaar') {
              _isAadhaarVerified = true;
            } else {
              _isPanVerified = true;
            }
            _showSuccess('$type verified successfully!');
          } else {
            if (type == 'aadhaar') {
              _aadhaarError = result.reason;
              _aadhaarFile = null; // Clear file on failure
            } else {
              _panError = result.reason;
              _panFile = null; // Clear file on failure
            }
            _showErrorDialog(type, result.reason ?? 'Verification failed');
          }
        });
      }
    }
  }

  void _removeDocument(String type) {
    setState(() {
      if (type == 'aadhaar') {
        _aadhaarFile = null;
        _isAadhaarVerified = false;
        _aadhaarError = null;
      } else {
        _panFile = null;
        _isPanVerified = false;
        _panError = null;
      }
    });
  }

  void _showErrorDialog(String type, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$type Verification Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    // Validation Step 2
    if (_universityController.text.trim().isEmpty) {
      _showError('Please enter your university/college');
      return;
    }
    // Bio is optional but recommended
    // Skills are optional but recommended for helpers
    // Phone number is now mandatory (10 digits)
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    // Document Verification Check
    if (!_isAadhaarVerified) {
      _showError('Please upload and verify your Aadhaar card');
      return;
    }
    if (!_isPanVerified) {
      _showError('Please upload and verify your PAN card');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      String userId;

      if (widget.isGoogleSignIn) {
        userId = authService.user!.uid;
      } else {
        final userCredential = await authService.signUpWithEmailOnly(
          _emailController.text.trim(),
          _passwordController.text,
        );
        userId = userCredential.user!.uid;
      }

      await userService.createUserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _isHelper ? 'helper' : 'seeker',
        university: _universityController.text.trim(),
        bio: _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        skills: _isHelper ? _skills : [],
      );

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Sign up failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              _previousStep();
            } else {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            }
          },
        ),
        title: Text(
          "Sign Up",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildStep1(theme), _buildStep2(theme)],
          ),
          if (_isLoading)
            Container(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressHeader(
            step: 1,
            title: "Basic Info",
            colorScheme: colorScheme,
          ),
          SizedBox(height: 32.h),
          Text(
            "Create Your Account",
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Join your campus community to start earning or hiring.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            "I want to...",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.school,
                  title: "Earn Money",
                  subtitle: "Student Helper",
                  isSelected: _isHelper,
                  onTap: () => setState(() => _isHelper = true),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _RoleCard(
                  icon: Icons.business_center,
                  title: "Hire Help",
                  subtitle: "Community Seeker",
                  isSelected: !_isHelper,
                  onTap: () => setState(() => _isHelper = false),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          _buildTextField(
            controller: _nameController,
            label: "Full Name",
            hint: "John Doe",
            icon: Icons.person,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          SizedBox(height: 24.h),
          _buildTextField(
            controller: _emailController,
            label: "Email",
            hint: "john.doe@example.com",
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          SizedBox(height: 24.h),
          if (!widget.isGoogleSignIn) ...[
            Text(
              "Password",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Create a password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text("Must be at least 8 characters.", style: textTheme.bodySmall),
            SizedBox(height: 40.h),
          ],
          SizedBox(
            height: 56.h,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: _buttonStyle(colorScheme),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Continue",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward, size: 20.sp),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: "Log in",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressHeader(
            step: 2,
            title: "Profile Details",
            colorScheme: colorScheme,
          ),
          SizedBox(height: 32.h),
          Text(
            "Almost there!",
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Tell us a bit more about yourself.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32.h),

          // University
          _buildTextField(
            controller: _universityController,
            label: "University / College",
            hint: "e.g. State University",
            icon: Icons.school_outlined,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          SizedBox(height: 24.h),

          // Phone Number
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number",
            hint: "+91 9876543210",
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          SizedBox(height: 24.h),

          // Document Verification
          Text(
            "Identity Verification",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          _buildDocumentUpload(
            label: "Aadhaar Card",
            isVerified: _isAadhaarVerified,
            file: _aadhaarFile,
            onTap: () => _pickAndVerifyDocument('aadhaar'),
            onDelete: () => _removeDocument('aadhaar'),
            onView: () async {
              if (_aadhaarFile != null) {
                final isPdf = _aadhaarFile!.path.toLowerCase().endsWith('.pdf');
                final result = await OpenFilex.open(
                  _aadhaarFile!.path,
                  type: isPdf ? 'application/pdf' : 'image/*',
                );
                if (result.type != ResultType.done) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot open file: ${result.message}'),
                    ),
                  );
                }
              }
            },
            colorScheme: colorScheme,
          ),
          if (_aadhaarError != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                _aadhaarError!,
                style: TextStyle(color: colorScheme.error, fontSize: 12.sp),
              ),
            ),
          SizedBox(height: 16.h),
          _buildDocumentUpload(
            label: "PAN Card",
            isVerified: _isPanVerified,
            file: _panFile,
            onTap: () => _pickAndVerifyDocument('pan'),
            onDelete: () => _removeDocument('pan'),
            onView: () async {
              if (_panFile != null) {
                final isPdf = _panFile!.path.toLowerCase().endsWith('.pdf');
                final result = await OpenFilex.open(
                  _panFile!.path,
                  type: isPdf ? 'application/pdf' : 'image/*',
                );
                if (result.type != ResultType.done) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot open file: ${result.message}'),
                    ),
                  );
                }
              }
            },
            colorScheme: colorScheme,
          ),
          if (_panError != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                _panError!,
                style: TextStyle(color: colorScheme.error, fontSize: 12.sp),
              ),
            ),

          SizedBox(height: 24.h),

          // Bio
          Text(
            "Short Bio",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "I am a CS student avoiding assignments...",
            ),
          ),
          SizedBox(height: 24.h),

          // Skills (for Helpers)
          if (_isHelper) ...[
            Text(
              "Skills (e.g. Coding, Moving, Design)",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(hintText: "Add a skill"),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _addSkill,
                  icon: Icon(
                    Icons.add_circle,
                    color: colorScheme.primary,
                    size: 32.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      onDeleted: () {
                        setState(() {
                          _skills.remove(skill);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 40.h),
          ],

          SizedBox(
            height: 56.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: _buttonStyle(colorScheme),
              child: _isLoading
                  ? CircularProgressIndicator(color: colorScheme.onPrimary)
                  : Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String label,
    required bool isVerified,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onView,
    required ColorScheme colorScheme,
  }) {
    // If no file is selected, show the upload placeholder
    if (file == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(12.w),
            color: colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(Icons.upload_file, color: colorScheme.primary),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Tap to upload",
                    style: TextStyle(fontSize: 12.sp, color: colorScheme.outline),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                "Upload",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // File selected - Show preview and delete option
    final String fileName = file.path.split('/').last;
    final bool isPdf = fileName.toLowerCase().endsWith('.pdf');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12.w),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: isVerified ? Colors.green : colorScheme.error,
            ),
            borderRadius: BorderRadius.circular(12.w),
            color: isVerified
                ? Colors.green.withValues(alpha: 0.1)
                : colorScheme.error.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Icon(
                isVerified
                    ? Icons.check_circle
                    : (isPdf ? Icons.picture_as_pdf : Icons.image),
                color: isVerified ? Colors.green : colorScheme.error,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isVerified)
                      Text(
                        "Verification Failed",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onView,
                icon: Icon(
                  Icons.visibility_outlined,
                  color: colorScheme.primary,
                ),
                tooltip: "View file",
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                tooltip: "Remove file",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader({
    required int step,
    required String title,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Step $step of 2",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(fontSize: 14.sp, color: colorScheme.outline),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.w),
          child: LinearProgressIndicator(
            value: step == 1 ? 0.5 : 1.0,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: 2.w,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.outline,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: colorScheme.onPrimary,
                  size: 16.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
