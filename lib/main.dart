import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/i18n_service.dart';
import 'services/ai_cognitive_engine.dart';
import 'services/auth_service.dart';
import 'services/schedule_service.dart';
import 'services/notification_service.dart';
import 'services/memory_lane_service.dart';
import 'services/webrtc_service.dart';
import 'services/news_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth_onboarding_screen.dart';
import 'screens/animated_splash_intro_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const PurbChetanaApp());
}

class PurbChetanaApp extends StatelessWidget {
  const PurbChetanaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => I18nService()),
        ChangeNotifierProvider(create: (_) => AiCognitiveEngine()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider2<I18nService, AuthService, ScheduleService>(
          create: (_) => ScheduleService(),
          update: (_, i18n, auth, schedule) {
            schedule?.updateI18n(i18n);
            schedule?.updateAuth(auth);
            return schedule ?? ScheduleService();
          },
        ),
        ChangeNotifierProvider(create: (_) => MemoryLaneService()),
        ChangeNotifierProvider(create: (_) => WebRTCService()),
        ChangeNotifierProvider(create: (_) => NewsService()),
      ],
      child: Consumer<I18nService>(
        builder: (context, i18n, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: '${i18n.translate("appName")} - ${i18n.translate("tagline")}',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF61C5B0),
                primary: const Color(0xFF61C5B0),
                secondary: const Color(0xFF23B39B),
                surface: const Color(0xFFFDF0E6),
                onSurface: const Color(0xFF1B2824),
              ),
              fontFamily: 'Comic Relief',
              fontFamilyFallback: const ['Roboto', 'Noto Serif Tamil', 'Vijaya', 'Comic Relief', 'sans-serif'],
              scaffoldBackgroundColor: const Color(0xFFFDF0E6),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: const Color(0xFF1B2824), fontFamily: 'Comic Relief'),
                bodyMedium: TextStyle(color: const Color(0xFF1B2824), fontFamily: 'Comic Relief'),
                titleLarge: TextStyle(color: const Color(0xFF1B2824), fontWeight: FontWeight.bold, fontFamily: 'Comic Relief'),
              ),
            ),
            home: const AppRootWrapper(),
          );
        },
      ),
    );
  }
}

class AppRootWrapper extends StatefulWidget {
  const AppRootWrapper({Key? key}) : super(key: key);

  @override
  State<AppRootWrapper> createState() => _AppRootWrapperState();
}

class _AppRootWrapperState extends State<AppRootWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        // 1. Wait for AuthService to restore persisted session from SharedPreferences
        if (!auth.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF0E6),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF61C5B0),
              ),
            ),
          );
        }

        // 2. Show splash screen on startup
        if (_showSplash) {
          return AnimatedSplashIntroScreen(
            onFinish: () {
              if (mounted) {
                setState(() {
                  _showSplash = false;
                });
              }
            },
          );
        }

        // 3. Once logged in on a device, NEVER show Senior Elder/Caretaker onboarding screen again!
        if (auth.isLoggedIn) {
          return const MainNavigationScreen();
        }

        // 4. Show role selection onboarding ONLY if user is not logged in
        return AuthOnboardingScreen(
          onComplete: () {},
        );
      },
    );
  }
}
