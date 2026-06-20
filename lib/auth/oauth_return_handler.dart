import 'oauth_return_handler_stub.dart'
    if (dart.library.html) 'oauth_return_handler_web.dart' as platform;

/// Handles OAuth return URLs on web (e.g. user canceled Google sign-in).
abstract final class OAuthReturnHandler {
  static String? canceledMessageFromCurrentUrl() {
    return platform.oauthCanceledMessageFromCurrentUrl();
  }

  static void cleanCurrentUrl() {
    platform.cleanOAuthParamsFromCurrentUrl();
  }

  static String origin() => platform.webOrigin();
}