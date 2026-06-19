import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/google_config.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _googleOpenIdScopes = <String>[
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  SupabaseClient get _client => Supabase.instance.client;

  bool _googleSignInInitialized = false;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  /// Prepares [GoogleSignIn] on platforms that use the native SDK.
  Future<void> initializeGoogleSignIn() async {
    if (_googleSignInInitialized || kIsWeb) {
      return;
    }

    await GoogleSignIn.instance.initialize(
      clientId: GoogleConfig.iosClientId.isEmpty
          ? null
          : GoogleConfig.iosClientId,
      serverClientId: GoogleConfig.webClientId.isEmpty
          ? null
          : GoogleConfig.webClientId,
    );
    _googleSignInInitialized = true;
  }

  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in with Google via Supabase.
  ///
  /// - **Web:** Supabase OAuth redirect flow.
  /// - **iOS/Android:** [google_sign_in] + Supabase ID token exchange.
  Future<void> signInWithGoogle() async {
    // Web uses Supabase OAuth (Google client is configured in Supabase dashboard).
    // Native platforms need GOOGLE_WEB_CLIENT_ID at compile time.
    if (!kIsWeb) {
      _assertGoogleConfigured();
    }

    if (kIsWeb) {
      await _signInWithGoogleOAuth();
      return;
    }

    await initializeGoogleSignIn();
    await _signInWithGoogleNative();
  }

  /// Signs in with X (Twitter) via Supabase OAuth on all platforms.
  ///
  /// Configure the Twitter provider in Supabase Dashboard → Authentication
  /// → Providers → Twitter (X). Redirect URLs must include your app origin.
  Future<void> signInWithX() async {
    await _signInWithOAuth(OAuthProvider.twitter);
  }

  Future<void> _signInWithGoogleOAuth() async {
    await _signInWithOAuth(OAuthProvider.google);
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: _oauthRedirectUrl(),
    );
  }

  Future<void> _signInWithGoogleNative() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthException(
        'Google Sign-In is not supported on this platform.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate(
      scopeHint: _googleOpenIdScopes,
    );

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('No Google ID token found.');
    }

    final authorization = await googleUser.authorizationClient.authorizeScopes(
      _googleOpenIdScopes,
    );

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  String _oauthRedirectUrl() {
    final base = Uri.base;
    final path = base.path.endsWith('/') ? base.path : '${base.path}/';
    return '${base.origin}$path';
  }

  void _assertGoogleConfigured() {
    if (!GoogleConfig.isConfigured) {
      throw const AuthException(
        'Google Sign-In is not configured. Set GOOGLE_WEB_CLIENT_ID '
        '(see lib/config/google_config.dart).',
      );
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _client.auth.signOut();
  }

  static String messageFromError(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Google sign in was canceled.';
      }
      return error.description ?? 'Google sign in failed.';
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}