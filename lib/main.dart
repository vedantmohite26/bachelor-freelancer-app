import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:freelancer/core/theme/app_theme.dart';
import 'package:freelancer/core/services/auth_service.dart';
import 'package:freelancer/core/services/firestore_service.dart';
import 'package:freelancer/core/services/job_service.dart';
import 'package:freelancer/core/services/user_service.dart';
import 'package:freelancer/core/services/rating_service.dart';
import 'package:freelancer/core/services/leaderboard_service.dart';
import 'package:freelancer/core/services/location_service.dart';
import 'package:freelancer/core/services/notification_service.dart';
import 'package:freelancer/core/services/local_notification_service.dart';
import 'package:freelancer/core/services/wallet_service.dart';
import 'package:freelancer/core/services/community_service.dart';
import 'package:freelancer/core/services/chat_service.dart';
import 'package:freelancer/core/services/cloudinary_service.dart';
import 'package:freelancer/core/services/friend_service.dart';
import 'package:freelancer/core/services/category_service.dart';
import 'package:freelancer/core/services/rewards_service.dart';
import 'package:freelancer/core/services/payment_service.dart';
import 'package:freelancer/features/finance_assistant/services/finance_service.dart';
import 'package:freelancer/features/auth/screens/loading_screen.dart';
import 'package:freelancer/features/auth/screens/login_screen.dart';
import 'package:freelancer/features/auth/screens/sign_up_screen.dart';
import 'package:freelancer/features/safety/screens/safety_center_screen.dart';
import 'package:freelancer/features/home/screens/home_screen.dart';
import 'package:freelancer/features/jobs/screens/create_task_screen.dart';
import 'package:freelancer/features/auth/screens/welcome_screen.dart';
import 'package:freelancer/core/widgets/premium_app_loader.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  await LocalNotificationService.initialize();

  // Enable Edge-to-Edge UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set transparent system bars to let app content draw behind
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      // Icon brightness will be handled by the theme
    ),
  );

  // Set preferred orientations - portrait only for better UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Disable runtime font fetching — use bundled fonts only (faster startup)
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => WalletService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => JobService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => RatingService()),
        Provider(create: (_) => LeaderboardService()),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => CommunityService()),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => CloudinaryService()),
        Provider(create: (_) => FriendService()),
        Provider(create: (_) => CategoryService()),
        Provider(create: (_) => RewardsService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        Provider(create: (_) => FinanceService()),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return MaterialApp(
            title: 'Unnati Freelancer',
            debugShowCheckedModeBanner: false,
            // Pass dynamic schemes to AppTheme
            theme: AppTheme.lightTheme(lightDynamic).copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: AppTheme.darkTheme(darkDynamic).copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: ThemeMode.system,
            // Start with loading screen
            // Named routes for efficient navigation
            routes: {
              '/': (context) => const LoadingScreen(),
              '/auth': (context) => const _AuthWrapper(),
              '/welcome': (context) => const WelcomeScreen(),
              '/safety': (context) => const SafetyCenterScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(isSeeker: true), // Default
              '/create-task': (context) => const CreateTaskScreen(),
            },
          );
        },
      ),
    );
  }
}

// Smart redirection based on auth state and user role
// Smart redirection based on auth state and user role
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context, listen: false);

    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    // Use StreamBuilder to listen for real-time profile updates (like role changes)
    return StreamBuilder<Map<String, dynamic>?>(
      stream: userService.getUserProfileStream(authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumAppLoader(statusMessage: "Verifying profile...");
        }

        // If profile doesn't exist, redirect to SignUpScreen to complete profile
        if (snapshot.hasError || snapshot.data == null) {
          return const SignUpScreen(isGoogleSignIn: true);
        }

        final isSeeker = snapshot.data!['role'] == 'seeker';
        return HomeScreen(key: ValueKey(isSeeker), isSeeker: isSeeker);
      },
    );
  }
}
