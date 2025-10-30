import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/features/auth/application/auth_controller.dart';
import 'package:forum_alumni/features/auth/presentation/login_screen.dart';
import 'package:forum_alumni/features/auth/presentation/register_screen.dart';
import 'package:forum_alumni/features/auth/presentation/pending_screen.dart';
import 'package:forum_alumni/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:forum_alumni/features/forum/presentation/create_post_screen.dart';
import 'package:forum_alumni/features/forum/presentation/home_screen.dart';
import 'package:forum_alumni/features/forum/presentation/post_detail_screen.dart';
import 'package:forum_alumni/features/profile/presentation/profile_screen.dart';
import 'package:forum_alumni/features/search/presentation/search_screen.dart';
import 'package:forum_alumni/features/notifications/presentation/notifications_screen.dart';
import 'package:forum_alumni/features/export/presentation/export_screen.dart';
import 'package:forum_alumni/features/settings/presentation/settings_screen.dart';
import 'package:forum_alumni/core/presentation/splash_screen.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        name: RegisterScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RegisterScreen(),
        ),
      ),
      GoRoute(
        path: PendingScreen.routePath,
        name: PendingScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PendingScreen(),
        ),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeScreen(),
        ),
        routes: [
          GoRoute(
            path: PostDetailScreen.routePath,
            name: PostDetailScreen.routeName,
            pageBuilder: (context, state) {
              final postId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return MaterialPage<void>(
                key: state.pageKey,
                child: PostDetailScreen(postId: postId),
              );
            },
          ),
          GoRoute(
            path: CreatePostScreen.routePath,
            name: CreatePostScreen.routeName,
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const CreatePostScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: SearchScreen.routePath,
        name: SearchScreen.routeName,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: NotificationsScreen.routePath,
        name: NotificationsScreen.routeName,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: ExportScreen.routePath,
        name: ExportScreen.routeName,
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AdminDashboardScreen.routePath,
        name: AdminDashboardScreen.routeName,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
    ],
    redirect: notifier.redirect,
    observers: [
      _RouterLogger(),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authNotifierProvider);

    final bool initialized = auth.initialized;
    final bool authenticating = auth.status == AuthStatus.authenticating;
    final String path = state.uri.path;

    final bool isSplash = path == SplashScreen.routePath;
    final bool isLogin = path == LoginScreen.routePath;
    final bool isRegister = path == RegisterScreen.routePath;
    final bool isPending = path == PendingScreen.routePath;

    if (!initialized || authenticating) {
      return isSplash ? null : SplashScreen.routePath;
    }

    if (!auth.isAuthenticated) {
      if (auth.isPendingApproval) {
        return isPending ? null : PendingScreen.routePath;
      }

      if (isLogin || isRegister) {
        return null;
      }

      return LoginScreen.routePath;
    }

    if (auth.isPendingApproval) {
      return isPending ? null : PendingScreen.routePath;
    }

    if (isLogin || isRegister || isPending || isSplash) {
      return HomeScreen.routePath;
    }

    return null;
  }
}

class _RouterLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('[Router] push: ${route.settings.name ?? route.settings.arguments}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('[Router] pop: ${route.settings.name ?? route.settings.arguments}');
    super.didPop(route, previousRoute);
  }
}
