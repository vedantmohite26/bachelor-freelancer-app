import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelancer/core/services/location_service.dart';

class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  // Local state for optimistic updates
  bool _blurContact = true;
  bool _profileVisibility = false;
  bool _safeWalk = false;
  bool _isLoading = true;
  List<Map<String, String>> _trustedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userService = Provider.of<UserService>(context, listen: false);
    final profile = await userService.getUserProfile(userId);

    if (profile != null) {
      final settings = profile['safetySettings'] as Map<String, dynamic>?;
      final contacts = profile['trustedContacts'] as List?;

      if (mounted) {
        setState(() {
          if (settings != null) {
            _blurContact = settings['blurContact'] ?? true;
            _profileVisibility = settings['profileVisibility'] ?? false;
            _safeWalk = settings['safeWalk'] ?? false;
          }

          if (contacts != null) {
            _trustedContacts = contacts
                .map((c) => Map<String, String>.from(c))
                .toList();
          }

          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _locationService = LocationService();

  Future<void> _updateSetting(String key, bool value) async {
    HapticFeedback.lightImpact();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userService = Provider.of<UserService>(context, listen: false);

    // Handle Safe-Walk Toggle
    if (key == 'safeWalk') {
      if (value) {
        // Turning ON
        final started = await _locationService.startLocationSharing(userId);
        if (!started) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission required for Safe-Walk. Please enable it in settings.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Don't update state if failed
        }

        // Auto-share via WhatsApp if trusted contact exists
        if (_trustedContacts.isNotEmpty) {
          final contact = _trustedContacts.first;
          final phone = contact['phone'];
          if (phone != null && phone.isNotEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening WhatsApp to share location with ${contact['name']}...',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            // Add a small delay to ensure UI updates before switching apps
            await Future.delayed(const Duration(milliseconds: 500));
            await _shareLocationViaWhatsApp(phoneNumber: phone);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tip: Add a trusted contact to auto-share location!',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Turning OFF
        await _locationService.stopLocationSharing(userId);
      }
    }

    // Optimistic update
    setState(() {
      if (key == 'blurContact') _blurContact = value;
      if (key == 'profileVisibility') _profileVisibility = value;
      if (key == 'safeWalk') _safeWalk = value;
    });

    await userService.updateSafetySettings(userId, {
      'blurContact': _blurContact,
      'profileVisibility': _profileVisibility,
      'safeWalk': _safeWalk,
    });
    if (!mounted) return;
  }

  Future<void> _launchDialer(String phoneNumber) async {
    HapticFeedback.mediumImpact();
    // Sanitize phone number
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanedNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid phone number')));
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);
    debugPrint("Launching dialer for: $cleanedNumber");

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $cleanedNumber')),
        );
      }
    }
  }

  Future<void> _shareLocationViaWhatsApp({String? phoneNumber}) async {
    HapticFeedback.mediumImpact();
    // 1. Get current location
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch location. Is GPS on?')),
        );
      }
      return;
    }

    // 2. Create Links
    final mapLink =
        "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

    final message =
        "I'm using Unnati Safe-Walk! Track my live status or see my location here: $mapLink";

    // 3. Launch WhatsApp
    Uri whatsappUrl;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Sanitize phone number (remove non-digits, ensure country code if needed)
      // Assuming input is largely correct or local, but let's strip non-digits/plus
      String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      // If it doesn't start with +, maybe add country code?
      // For now, let's assume user enters valid format or local number.
      // Whatsapp usually handles international format best.

      whatsappUrl = Uri.parse(
        "whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(message)}",
      );
    } else {
      whatsappUrl = Uri.parse(
        "whatsapp://send?text=${Uri.encodeComponent(message)}",
      );
    }

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        // Fallback to web if app not installed (unlikely on Android but good practice)
        final webUrl = Uri.parse(
          "https://wa.me/?text=${Uri.encodeComponent(message)}",
        );
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open WhatsApp')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }

  void _callTrustedContact() {
    HapticFeedback.mediumImpact();
    if (_trustedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No trusted contacts added. Please add one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      _showTrustedContactsModal();
      return;
    }

    // Directly dial the first trusted contact
    final contact = _trustedContacts.first;
    final name = contact['name'] ?? 'Contact';
    final phone = contact['phone'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $name...'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    _launchDialer(phone);
  }

  void _showTrustedContactsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrustedContactsModal(
        contacts: _trustedContacts,
        onAddContact: _addTrustedContact,
        onRemoveContact: _removeTrustedContact,
      ),
    );
  }

  void _showSafetyTipsModal() {
    final tips = [
      {
        'icon': Icons.verified_user,
        'title': 'Verify Identity',
        'desc':
            'Always check the student\'s profile badge and recent reviews before accepting a gig meeting.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Stay on Platform',
        'desc':
            'Keep all communication and payments within the Unnati app to ensure you are protected.',
        'color': Colors.green,
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Protect Personal Info',
        'desc':
            'Never share sensitive details like OTPs, bank passwords, or home address in chat.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Share Location',
        'desc':
            'Enable the Safe-Walk feature to share your real-time location with trusted contacts during gigs.',
        'color': Colors.red,
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Trust Your Instincts',
        'desc':
            'If a situation feels unsafe or uncomfortable, leave immediately and contact support.',
        'color': Colors.purple,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Safety Tips for Helpers",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: tips.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 32),
                  padding: const EdgeInsets.only(bottom: 32),
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (tip['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tip['icon'] as IconData,
                            color: tip['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTrustedContact(String name, String phone) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final newContact = {'name': name, 'phone': phone};

    setState(() {
      _trustedContacts.add(newContact);
    });

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.addTrustedContact(userId, newContact);
  }

  Future<void> _removeTrustedContact(Map<String, String> contact) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _trustedContacts.removeWhere((c) => c['phone'] == contact['phone']);
    });

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.removeTrustedContact(userId, contact);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Help & Safety Center",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Safety First",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We prioritize student safety. Access emergency tools and manage your privacy instantly.",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "Quick Assistance",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _SafetyCard(
                    icon: Icons.security,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEE2E2),
                    title: "Campus Security",
                    subtitle: "Direct line to police",
                    onTap: () => _launchDialer('100'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SafetyCard(
                    icon: Icons.phone_in_talk,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    title: "Call Contact",
                    subtitle: "Emergency call",
                    onTap: _callTrustedContact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SafetyCard(
                    icon: Icons.lightbulb_outline,
                    color: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFDBEAFE),
                    title: "Safety Tips",
                    subtitle: "Best practices",
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showSafetyTipsModal();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SafetyCard(
                    icon: Icons.perm_contact_calendar_outlined,
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    title: "Trusted Contacts",
                    subtitle: "Manage list",
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showTrustedContactsModal();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Safe-Walk Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainer
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outlineVariant
                      : const Color(0xFFDBEAFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_walk,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Safe-Walk",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _safeWalk,
                        onChanged: (v) => _updateSetting('safeWalk', v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.primaryBlue,
                        inactiveTrackColor: isDark ? Colors.grey[700] : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Share your real-time location with trusted contacts during a gig or while walking home.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: isDark
                        ? colorScheme.outlineVariant
                        : const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _safeWalk ? "Active - Sharing Location" : "Inactive",
                        style: GoogleFonts.inter(
                          color: _safeWalk
                              ? AppTheme.primaryBlue
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (_safeWalk)
                        IconButton(
                          onPressed: () => _shareLocationViaWhatsApp(),
                          icon: const Icon(Icons.share, color: Colors.green),
                          tooltip: 'Share via WhatsApp',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Privacy Controls",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface, // Dynamic color
              ),
            ),
            const SizedBox(height: 16),

            _PrivacySwitch(
              icon: Icons.blur_on,
              title: "Blur Contact Info",
              subtitle: "Hide number until gig starts",
              value: _blurContact,
              onChanged: (v) => _updateSetting('blurContact', v),
            ),
            const SizedBox(height: 12),
            _PrivacySwitch(
              icon: Icons.visibility_off_outlined,
              title: "Profile Visibility",
              subtitle: "Only visible to hired students",
              value: _profileVisibility,
              onChanged: (v) => _updateSetting('profileVisibility', v),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support contact feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: const Text("Contact 24/7 Support"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.2) : bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacySwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[400],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primaryBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
        ],
      ),
    );
  }
}

class _TrustedContactsModal extends StatefulWidget {
  final List<Map<String, String>> contacts;
  final Function(String, String) onAddContact;
  final Function(Map<String, String>) onRemoveContact;

  const _TrustedContactsModal({
    required this.contacts,
    required this.onAddContact,
    required this.onRemoveContact,
  });

  @override
  State<_TrustedContactsModal> createState() => _TrustedContactsModalState();
}

class _TrustedContactsModalState extends State<_TrustedContactsModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Trusted Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty) {
                widget.onAddContact(
                  _nameController.text.trim(),
                  _phoneController.text.trim(),
                );
                _nameController.clear();
                _phoneController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Trusted Contacts",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_phone_outlined,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No trusted contacts yet\nThese contacts will be notified during Safe-Walk.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.contacts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final contact = widget.contacts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark
                        ? AppTheme.growthGreen.withValues(alpha: 0.2)
                        : const Color(0xFFD1FAE5),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppTheme.growthGreen,
                    ),
                  ),
                  title: Text(
                    contact['name'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    contact['phone'] ?? '',
                    style: GoogleFonts.inter(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error.withValues(alpha: 0.8),
                    ),
                    onPressed: () => widget.onRemoveContact(contact),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add New Contact"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
