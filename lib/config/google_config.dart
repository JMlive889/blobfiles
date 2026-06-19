/// Google OAuth client IDs from Google Cloud Console.
///
/// Setup:
/// 1. Supabase Dashboard → Authentication → Providers → Google (enable).
/// 2. Google Cloud → APIs & Services → Credentials → create OAuth client IDs.
/// 3. Add the **Web client ID** here and in the Supabase Google provider.
/// 4. Add `http://localhost:5173` to Supabase → Authentication → URL Configuration
///    → Redirect URLs (and your production URL when deployed).
abstract final class GoogleConfig {
  /// Web OAuth 2.0 client ID (ends with `.apps.googleusercontent.com`).
  /// Used for Flutter web OAuth and as [serverClientId] on Android.
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS OAuth client ID. Optional on web/Android.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => webClientId.isNotEmpty;
}