// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/posts_list_screen.dart';
import 'screens/post_editor_screen.dart';
import 'screens/stories_review_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/media_library_screen.dart';
import 'screens/page_content_screen.dart';
import 'screens/analytics_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: JhomeAdminApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: AuthChangeNotifier(),
    redirect: (context, state) {
      final isLoggedIn = auth.value != null;
      final isLoginPage = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      ShellRoute(
        builder: (c, s, child) => DashboardScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardHome()),
          GoRoute(path: '/posts', builder: (c, s) => const PostsListScreen()),
          GoRoute(path: '/posts/new', builder: (c, s) => const PostEditorScreen()),
          GoRoute(path: '/posts/edit/:id', builder: (c, s) => PostEditorScreen(postId: s.pathParameters['id'])),
          GoRoute(path: '/stories', builder: (c, s) => const StoriesReviewScreen()),
          GoRoute(path: '/messages', builder: (c, s) => const MessagesScreen()),
          GoRoute(path: '/media', builder: (c, s) => const MediaLibraryScreen()),
          GoRoute(path: '/pages', builder: (c, s) => const PageContentScreen()),
          GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        ],
      ),
    ],
  );
});

class JhomeAdminApp extends ConsumerWidget {
  const JhomeAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Jhome Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

// لإجبار GoRouter على التحديث عند تغيّر حالة المستخدم
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}