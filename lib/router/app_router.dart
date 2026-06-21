import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';
import '../services/auth_service.dart';
import '../screens/help_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/team_detail_screen.dart';
import '../screens/templates_screen.dart';
import '../theme/app_colors.dart';

part 'app_router.g.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies [GoRouter] when [authProvider] changes so redirects re-run.
class GoRouterAuthRefresh extends ChangeNotifier {
  GoRouterAuthRefresh(Ref ref) {
    _subscription = ref.listen(authProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshListenable = GoRouterAuthRefresh(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: _initialLocation(ref),
    refreshListenable: refreshListenable,
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/landing',
      ),
      GoRoute(
        path: '/landing',
        name: 'landing',
        pageBuilder: (context, state) => _noTransition(
          state,
          const LandingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _noTransition(
          state,
          const LoginScreen(),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => _noTransition(
              state,
              const SizedBox.shrink(),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const ProfileScreen(),
                ),
              ),
              GoRoute(
                path: 'templates',
                name: 'templates',
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const TemplatesScreen(),
                ),
              ),
              GoRoute(
                path: 'help',
                name: 'help',
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const HelpScreen(),
                ),
              ),
              GoRoute(
                path: 'teams/:teamId',
                name: 'teamDetail',
                pageBuilder: (context, state) => _noTransition(
                  state,
                  TeamDetailScreen(
                    teamId: state.pathParameters['teamId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

NoTransitionPage<void> _noTransition(
  GoRouterState state,
  Widget child,
) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

String _initialLocation(Ref ref) {
  return _isAuthenticated(ref) ? '/library' : '/landing';
}

bool _isAuthenticated(Ref ref) {
  final auth = ref.read(authProvider);
  return auth.isAuthenticated || AuthService.instance.isAuthenticated;
}

String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;

  if (_isAuthenticated(ref)) {
    if (location == '/login') {
      return '/library';
    }
    return _legacyShellRedirect(location);
  }

  if (_isProtectedRoute(location)) {
    return '/login';
  }

  return _legacyShellRedirect(location);
}

String? _legacyShellRedirect(String location) {
  return switch (location) {
    '/profile' => '/library/profile',
    '/templates' => '/library/templates',
    '/help' => '/library/help',
    _ => null,
  };
}

bool _isProtectedRoute(String location) {
  return location == '/library' || location.startsWith('/library/');
}