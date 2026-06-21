import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'auth_status.dart';

part 'auth_provider.g.dart';

/// Immutable snapshot of authentication state for routing and UI.
@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  final AuthStatus status;
  final User? user;

  bool get isLoading => status == AuthStatus.unknown;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  User? get currentUser => user;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

/// Central auth state for the app. Subscribes to Supabase [AuthState] changes.
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() {
    final auth = AuthService.instance;
    final initialSessionReady = Completer<void>();

    final subscription = auth.authStateChanges.listen((event) {
      state = _stateFromSession(event.session);

      if (event.event == AuthChangeEvent.initialSession &&
          !initialSessionReady.isCompleted) {
        initialSessionReady.complete();
      }
    });

    ref.onDispose(subscription.cancel);

    // Supabase may emit initialSession before this provider is created.
    unawaited(
      initialSessionReady.future
          .timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {},
          )
          .then((_) {
        state = _stateFromSession(auth.currentSession);
      }),
    );

    return _stateFromSession(auth.currentSession);
  }

  /// Re-reads the Supabase client session. Call after sign-in/sign-up so
  /// routing updates immediately when the stream has not emitted yet.
  void syncFromClient() {
    state = _stateFromSession(AuthService.instance.currentSession);
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
  }

  AuthState _stateFromSession(Session? session) {
    if (session != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
    }

    final auth = AuthService.instance;
    if (auth.currentSession != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        user: auth.currentUser,
      );
    }

    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Stable auth user id for data providers. Rebuilds only when the id changes.
@Riverpod(keepAlive: true)
String? authUserId(Ref ref) {
  return ref.watch(authProvider).currentUser?.id;
}