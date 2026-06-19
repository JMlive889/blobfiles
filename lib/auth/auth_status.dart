/// High-level authentication state used for routing and UI.
enum AuthStatus {
  /// Initial session check has not completed yet.
  unknown,

  /// A valid Supabase session is present.
  authenticated,

  /// No active session.
  unauthenticated,
}