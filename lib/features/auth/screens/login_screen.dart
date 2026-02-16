import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/features/auth/screens/sign_up_screen.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSeeker = true;
  // UI State
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    // Get UserService to update role
    final userService = Provider.of<UserService>(
      context,
      listen: false,
    ); // Added

    try {
      final userCredential = await authService.signInWithEmailOnly(
        email,
        password,
      ); // Capture credential

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        // Check if profile exists before updating
        final profile = await userService.getUserProfile(userId);

        if (profile == null) {
          if (mounted) {
            // Profile missing, navigate to SignUp to complete profile
            // We use isGoogleSignIn=true as a flag for "existing auth, missing profile"
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SignUpScreen(isGoogleSignIn: true),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please complete your profile details."),
              ),
            );
          }
          return;
        }

        // Update the user's role based on their selection
        try {
          await userService.updateProfile(userId, {
            'role': isSeeker ? 'seeker' : 'helper',
          });
          debugPrint(
            "LoginScreen: Role updated to ${isSeeker ? 'seeker' : 'helper'}",
          );
        } catch (e) {
          debugPrint("LoginScreen: User role update failed: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Warning: Failed to update role: $e")),
            );
          }
          // We continue to navigation even if role update failed,
          // because auth succeeded. But user might land on wrong dashboard.
          // Ideally we should retry or stop? For now, proceed but warn.
        }
      }

      if (mounted) {
        // Debug Dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Debug: Verification"),
            content: Text(
              "Going to Home as: ${isSeeker ? 'SEEKER' : 'HELPER'}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        if (!mounted) return;

        // Direct navigation to enforce the selected role immediately
        // preventing _AuthWrapper from overriding us with old data
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(isSeeker: isSeeker)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo / Header
            Icon(Icons.flash_on_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Welcome to Freelancer",
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("The Campus Job Marketplace", style: textTheme.bodyMedium),
            const SizedBox(height: 40),

            // Mock Hero Image Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 80,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Role Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      title: "I need help",
                      isSelected: isSeeker,
                      onTap: () => setState(() => isSeeker = true),
                    ),
                  ),
                  Expanded(
                    child: _RoleButton(
                      title: "I want to work",
                      isSelected: !isSeeker,
                      onTap: () => setState(() => isSeeker = false),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Email / Password Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
              },
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: "Sign Up",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Social Login (Mock)
            Text("Or continue with", style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  onTap: () async {
                    setState(() => _isLoading = true);
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final userService = Provider.of<UserService>(
                      context,
                      listen: false,
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final credential = await authService.signInWithGoogle();

                      if (credential == null || credential.user == null) {
                        return;
                      }

                      final userId = credential.user!.uid;

                      // Check profile existence (ALLOW BACKGROUND EXECUTION)
                      // We removed 'if (!mounted) return' to ensure this runs even if AuthWrapper unmounts us.

                      final profile = await userService.getUserProfile(userId);

                      if (profile == null) {
                        // Only for new users do we need UI interaction.
                        if (!context.mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const SignUpScreen(isGoogleSignIn: true),
                          ),
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please complete your profile details.",
                            ),
                          ),
                        );
                        return;
                      }

                      // Update role (ALLOW BACKGROUND EXECUTION)
                      try {
                        await userService.updateProfile(userId, {
                          'role': isSeeker ? 'seeker' : 'helper',
                        });
                        debugPrint(
                          "LoginScreen(Google): Role force-updated to ${isSeeker ? 'seeker' : 'helper'}",
                        );
                      } catch (e) {
                        debugPrint(
                          "LoginScreen(Google): Role update failed: $e",
                        );
                      }

                      // Optional: explicit navigation if still mounted
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(isSeeker: isSeeker),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              "Google Sign-In Failed: ${e.toString()}",
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.apple, onTap: () {}),
              ],
            ),

            // Debug Bypass (For Demo)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  '/home',
                  arguments: {'isSeeker': isSeeker},
                );
              },
              child: Text("DEBUG: Skip Login", style: textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.onSurface : colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 32, color: colorScheme.onSurface),
      ),
    );
  }
}
