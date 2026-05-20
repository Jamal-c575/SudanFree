import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/job_provider.dart';
import 'providers/chat_provider.dart';
import 'services/notification_polling_service.dart';

import 'providers/search_provider.dart';

import 'views/auth/login_screen.dart';
import 'views/auth/profile_setup_screen.dart';
import 'views/home/home_screen.dart';
import 'widgets/common/loading_widget.dart';
import 'widgets/common/connectivity_wrapper.dart';
import 'services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/common/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';

class SudanFreeApp extends StatelessWidget {
  const SudanFreeApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()..loadLocations()),
        ChangeNotifierProvider(create: (_) => PostsProvider()..fetchPosts()),
        ChangeNotifierProvider(create: (_) => JobProvider()..fetchJobs()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => NotificationPollingService()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          return MaterialApp(
            navigatorKey: SudanFreeApp.navigatorKey,
            title: 'SudanFree',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 500),
            themeAnimationCurve: Curves.easeInOutCubic,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Check for updates asynchronously
              WidgetsBinding.instance.addPostFrameCallback((_) {
                UpdateService.checkForUpdate(context);
              });
              
              return ConnectivityWrapper(
                child: Stack(
                  children: [
                    if (child != null) child,
                  if (localeProvider.isLoading)
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const LoadingIndicator(size: 60),
                          const SizedBox(height: 24),
                          Text(
                            localeProvider.isArabic 
                                ? 'جاري تغيير اللغة...' 
                                : 'Changing Language...',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.status == AuthStatus.authenticated) {
                  if (authProvider.isNewUser || authProvider.user == null) {
                    return const ProfileSetupScreen();
                  }
                  return const HomeScreen();
                }
                
                if (authProvider.status == AuthStatus.initial || 
                    (authProvider.status == AuthStatus.loading && !authProvider.isManualSignIn)) {
                  return const SplashScreen();
                }
                
                // For AuthStatus.unauthenticated, AuthStatus.error, or loading during manual sign in
                return const OnboardingCheck();
              },
            ),
          );
        },
      ),
    );
  }
}

class OnboardingCheck extends StatefulWidget {
  const OnboardingCheck({super.key});

  @override
  State<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends State<OnboardingCheck> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !prefs.containsKey('has_seen_onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const SplashScreen();
    }
    
    if (_showOnboarding!) {
      return OnboardingScreen(
        onCompleted: () {
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }
    
    return const LoginScreen();
  }
}
