/// Username rules for BlobFiles profiles.
///
/// - 4–15 characters
/// - Letters, numbers, and underscores only
/// - Not a reserved name (case-insensitive)
abstract final class UsernameValidator {
  static const int minLength = 4;
  static const int maxLength = 15;

  /// Reserved usernames that cannot be claimed by users.
  /// Add new entries here as needed (stored lowercase).
  static const Set<String> reservedNames = {
    'admin',
    'support',
    'blobfiles',
    'moderator',
    'staff',
    'system',
    'official',
  };

  static final RegExp _allowedPattern = RegExp(r'^[a-zA-Z0-9_]+$');

  /// Returns `true` when [username] meets all validation rules.
  static bool isValidUsername(String username) {
    return getUsernameError(username) == null;
  }

  /// Returns an error message when invalid, or `null` when valid.
  static String? getUsernameError(String username) {
    final value = username.trim();

    if (value.length < minLength || value.length > maxLength) {
      return 'Username must be $minLength–$maxLength characters.';
    }

    if (!_allowedPattern.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores.';
    }

    if (reservedNames.contains(value.toLowerCase())) {
      return 'That username is reserved. Please choose another.';
    }

    return null;
  }
}