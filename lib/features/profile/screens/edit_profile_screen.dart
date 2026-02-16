import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/cloudinary_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _universityController;
  late TextEditingController _phoneController;
  late TextEditingController _skillController;

  List<String> _skills = [];
  Map<String, String> _skillCertificates = {};
  bool _isUploading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _universityController = TextEditingController();
    _phoneController = TextEditingController();
    _skillController = TextEditingController();

    _loadUserData();
  }

  void _loadUserData() {
    final userService = Provider.of<UserService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId != null) {
      // We can fetch fresh data or rely on what's passed.
      // Fetching fresh ensures we have the latest.
      userService.getUserProfile(userId).then((userData) {
        if (userData != null && mounted) {
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _universityController.text = userData['university'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';
            _profileImageUrl = userData['photoUrl'];

            final skillsList = userData['skills'] as List?;
            if (skillsList != null) {
              _skills = skillsList.map((s) => s.toString()).toList();
            }
            final certificatesMap =
                userData['skillCertificates'] as Map<String, dynamic>?;
            if (certificatesMap != null) {
              _skillCertificates = certificatesMap.map(
                (key, value) => MapEntry(key, value.toString()),
              );
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _universityController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a skill name first")),
      );
      return;
    }

    if (!_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Skill '$skill' added. Tap it to upload a certificate!",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Skill already added")));
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
      _skillCertificates.remove(skill);
    });
  }

  Future<void> _uploadCertificate(String skill) async {
    final cloudinaryService = Provider.of<CloudinaryService>(
      context,
      listen: false,
    );

    setState(() => _isUploading = true);
    try {
      final url = await cloudinaryService.pickAndUploadImage();
      if (url != null && mounted) {
        setState(() {
          _skillCertificates[skill] = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Certificate uploaded for $skill")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    final cloudinaryService = Provider.of<CloudinaryService>(
      context,
      listen: false,
    );

    setState(() => _isUploading = true);
    try {
      final url = await cloudinaryService.pickAndUploadImage();
      if (url != null && mounted) {
        setState(() {
          _profileImageUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture uploaded!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await userService.updateProfile(userId, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'university': _universityController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'photoUrl': _profileImageUrl,
        'skills': _skills,
        // Update searchable tokens as well if name changed (handled largely by create but good to update)
        'nameTokens': _nameController.text.trim().toLowerCase().split(
          RegExp(r'\s+'),
        ),
        'skillsLower': _skills.map((s) => s.toLowerCase()).toList(),
        'skillCertificates': _skillCertificates,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: colorScheme.onSurface),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Save",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(color: AppTheme.primaryBlue),
                ),
              // Avatar Placeholder (Edit functionality could be added here later)
              Center(
                child: Stack(
                  children: [
                    CachedNetworkAvatar(
                      imageUrl: _profileImageUrl,
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      fallbackIconColor: Colors.grey,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField("Full Name", _nameController, Icons.person),
              const SizedBox(height: 20),

              _buildTextField(
                "Bio",
                _bioController,
                Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                "University / College",
                _universityController,
                Icons.school,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                "Phone Number",
                _phoneController,
                Icons.phone,
                inputType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 24),

              const Text(
                "Skills",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        hintText: "Add a skill (e.g. Design)",
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSkill,
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppTheme.primaryBlue,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.map((skill) {
                  final hasCertificate = _skillCertificates.containsKey(skill);
                  return InputChip(
                    label: Text(skill),
                    avatar: hasCertificate
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        : const Icon(Icons.upload_file, size: 18),
                    onDeleted: () => _removeSkill(skill),
                    onPressed: () {
                      if (hasCertificate) {
                        _viewCertificate(skill, _skillCertificates[skill]!);
                      } else {
                        _uploadCertificate(skill);
                      }
                    },
                    backgroundColor: hasCertificate
                        ? Colors.green.withValues(alpha: 0.1)
                        : AppTheme.primaryBlue.withValues(alpha: 0.1),
                    deleteIconColor: Colors.red,
                    tooltip: hasCertificate
                        ? "Tap to view certificate"
                        : "Tap to upload certificate",
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _viewCertificate(String skill, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text("$skill Certificate"),
              leading: const CloseButton(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Re-upload",
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _uploadCertificate(skill); // Trigger upload
                  },
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(child: Text("Failed to load image")),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    bool isRequired = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: inputType,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Required";
            }
            if (label == "Phone Number" && value != null && value.isNotEmpty) {
              if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                return "Enter valid 10-digit number";
              }
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
