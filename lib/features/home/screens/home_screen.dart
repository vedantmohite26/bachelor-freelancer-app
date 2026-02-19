import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/features/home/screens/seeker_home_tab.dart';
import 'package:freelancer/features/home/screens/helper_dashboard_tab.dart';
import 'package:freelancer/features/jobs/screens/my_jobs_screen.dart';
import 'package:freelancer/features/jobs/screens/job_feed_screen.dart';
import 'package:freelancer/features/finance_assistant/screens/finance_dashboard_screen.dart';
import 'package:freelancer/features/activity/screens/activity_screen.dart';
import 'package:freelancer/features/profile/screens/my_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/widgets/cached_network_avatar.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isSeeker;
  final int initialIndex;

  const HomeScreen({super.key, this.isSeeker = true, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  // Lazy-loaded tab builders — tabs are only built on first visit
  late final List<Widget Function()> _tabBuilders;
  // Cache of built tabs — null means not yet visited
  final Map<int, Widget> _builtTabs = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _tabBuilders = widget.isSeeker
        ? [
            () => const SeekerHomeTab(),
            () => const MyJobsScreen(),
            () => const FinanceDashboardScreen(),
            () => const ActivityScreen(),
            () => const MyProfileScreen(),
          ]
        : [
            () => const HelperDashboardTab(),
            () => const JobFeedScreen(),
            () => const FinanceDashboardScreen(),
            () => const ActivityScreen(),
            () => const MyProfileScreen(),
          ];

    // Pre-build only the initial tab
    _builtTabs[_currentIndex] = _tabBuilders[_currentIndex]();

    // Initialize global notification listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user != null) {
        Provider.of<NotificationService>(
          context,
          listen: false,
        ).listenForNotifications(authService.user!.uid);
      }
    });
  }

  /// Get or build a tab lazily
  Widget _getTab(int index) {
    _builtTabs[index] ??= _tabBuilders[index]();
    return _builtTabs[index]!;
  }

  /// Handle back button press
  void _handlePopInvoked(bool didPop) {
    if (didPop) return;

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final userId = authService.user?.uid ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _handlePopInvoked(didPop);
      },
      child: Scaffold(
        // Lazy IndexedStack: only render visited tabs
        body: RepaintBoundary(
          child: IndexedStack(
            index: _currentIndex,
            children: List.generate(
              _tabBuilders.length,
              (i) => (i == _currentIndex || _builtTabs.containsKey(i))
                  ? _getTab(i)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        // Only the nav bar listens to profile stream (for avatar)
        bottomNavigationBar: StreamBuilder<Map<String, dynamic>?>(
          stream: userService.getUserProfileStream(userId),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final photoUrl = profile?['photoUrl'] as String?;

            final profileIcon = CachedNetworkAvatar(
              imageUrl: photoUrl,
              radius: 12,
            );

            final selectedProfileIcon = CachedNetworkAvatar(
              imageUrl: photoUrl,
              radius: 12,
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
            );

            final List<NavigationDestination> destinations = widget.isSeeker
                ? [
                    const NavigationDestination(
                      icon: Icon(Icons.search),
                      selectedIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Find Help',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.work_outline),
                      selectedIcon: Icon(
                        Icons.work,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Posted Jobs',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Finance',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(
                        Icons.notifications,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Activity',
                    ),
                    NavigationDestination(
                      icon: profileIcon,
                      selectedIcon: selectedProfileIcon,
                      label: 'Profile',
                    ),
                  ]
                : [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(
                        Icons.home,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Dashboard',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.work_outline),
                      selectedIcon: Icon(
                        Icons.work,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Find Jobs',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Finance',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(
                        Icons.notifications,
                        color: AppTheme.primaryBlue,
                      ),
                      label: 'Activity',
                    ),
                    NavigationDestination(
                      icon: profileIcon,
                      selectedIcon: selectedProfileIcon,
                      label: 'Profile',
                    ),
                  ];

            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              destinations: destinations,
            );
          },
        ),
      ),
    );
  }
}
