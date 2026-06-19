import 'package:web/web.dart' as web;

String? oauthCanceledMessageFromCurrentUrl() {
  final params = _paramsFromHref(web.window.location.href);
  final error = params['error'] ?? params['error_code'];
  final description = params['error_description'] ?? '';

  if (error == null && description.isEmpty) {
    return null;
  }

  final normalized = '${error ?? ''} $description'.toLowerCase();
  if (normalized.contains('access_denied') ||
      normalized.contains('cancel') ||
      normalized.contains('denied')) {
    return 'Sign in was canceled. You can try again or use email instead.';
  }

  if (description.isNotEmpty) {
    return description;
  }

  return 'Sign in could not be completed. Please try again.';
}

void cleanOAuthParamsFromCurrentUrl() {
  final origin = web.window.location.origin;
  web.window.history.replaceState(null, '', '$origin/login');
}

Map<String, String> _paramsFromHref(String href) {
  final uri = Uri.parse(href);
  final params = Map<String, String>.from(uri.queryParameters);

  if (uri.fragment.isNotEmpty) {
    params.addAll(Uri.splitQueryString(uri.fragment));
  }

  return params;
}