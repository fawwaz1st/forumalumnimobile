import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/auth/providers/auth_controller.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/splash_view.dart';
import '../features/posts/views/home_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/posts/views/post_detail_view.dart';
import '../features/posts/views/post_editor_view.dart';
import '../features/notifications/views/notifications_view.dart';
import '../features/main/main_shell.dart';
import '../features/settings/views/settings_view.dart';
import '../features/search/views/search_view.dart';
import '../features/profile/views/edit_profile_view.dart';
import '../features/profile/views/bookmarks_view.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) => const SplashView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (BuildContext context, GoRouterState state) => const HomeView(),
              routes: [
                GoRoute(
                  path: 'posts/new',
                  name: 'post_new',
                  builder: (BuildContext context, GoRouterState state) => const PostEditorView(),
                ),
                GoRoute(
                  path: 'posts/:id',
                  name: 'post_detail',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id']!;
                    return PostDetailView(id: id);
                  },
                ),
                GoRoute(
                  path: 'posts/:id/edit',
                  name: 'post_edit',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id']!;
                    return PostEditorView(id: id);
                  },
                ),
                GoRoute(
                  path: 'search',
                  name: 'search',
                  builder: (BuildContext context, GoRouterState state) => const SearchView(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (BuildContext context, GoRouterState state) => const NotificationsView(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (BuildContext context, GoRouterState state) => const ProfileView(),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  builder: (BuildContext context, GoRouterState state) => const SettingsView(),
                ),
                GoRoute(
                  path: 'edit',
                  name: 'edit_profile',
                  builder: (BuildContext context, GoRouterState state) => const EditProfileView(),
                ),
                GoRoute(
                  path: 'bookmarks',
                  name: 'bookmarks',
                  builder: (BuildContext context, GoRouterState state) => const BookmarksView(),
                ),
                GoRoute(
                  path: 'myposts',
                  name: 'my_posts',
                  builder: (BuildContext context, GoRouterState state) => const Scaffold(
                    body: Center(child: Text('Daftar Posting Saya.')),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (BuildContext context, GoRouterState state) => const RegisterView(),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register';
      final isLoggedIn = ref.read(isLoggedInProvider);
      final authState = ref.read(authControllerProvider);
      if (loc == '/splash') {
        if (authState.isLoading) return null;
        return isLoggedIn ? '/' : '/login';
      }
      if (!isLoggedIn) {
        if (loggingIn) return null;
        return '/login';
      }
      if (loggingIn) return '/';
      return null;
    },
  );
});

// (removed) Placeholder _MyPostsPage yang tidak dipakai
