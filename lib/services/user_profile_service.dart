import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  static const _selectColumns = 'id, username, full_name, avatar_url, bio';

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile?> fetchById(String userId) async {
    final data = await _client
        .from('users')
        .select(_selectColumns)
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return UserProfile.fromJson(data);
  }

  /// Creates the profile row if missing, otherwise updates it.
  Future<UserProfile> save({
    required String userId,
    required String username,
    String? fullName,
    String? bio,
  }) async {
    final trimmedUsername = username.trim();
    await _ensureUsernameAvailable(
      username: trimmedUsername,
      userId: userId,
    );

    final existing = await fetchById(userId);
    if (existing == null) {
      return _insert(
        userId: userId,
        username: trimmedUsername,
        fullName: fullName,
        bio: bio,
      );
    }

    return _update(
      userId: userId,
      username: trimmedUsername,
      fullName: fullName,
      bio: bio,
    );
  }

  Future<UserProfile> _insert({
    required String userId,
    required String username,
    String? fullName,
    String? bio,
  }) async {
    try {
      final data = await _client
          .from('users')
          .insert({
            'id': userId,
            'username': username,
            'full_name': fullName,
            'bio': bio,
          })
          .select(_selectColumns)
          .single();

      return UserProfile.fromJson(data);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<UserProfile> _update({
    required String userId,
    required String username,
    String? fullName,
    String? bio,
  }) async {
    try {
      final data = await _client
          .from('users')
          .update({
            'username': username,
            'full_name': fullName,
            'bio': bio,
          })
          .eq('id', userId)
          .select(_selectColumns)
          .maybeSingle();

      if (data == null) {
        throw const UserProfileUpdateException(
          'Profile not found. Your account may still be setting up.',
        );
      }

      return UserProfile.fromJson(data);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  /// Checks case-insensitive username availability for [userId].
  Future<bool> isUsernameAvailable({
    required String username,
    required String userId,
  }) async {
    final available = await _client.rpc(
      'is_username_available',
      params: {
        'p_username': username.trim(),
        'p_user_id': userId,
      },
    );
    return _parseAvailability(available);
  }

  Future<void> _ensureUsernameAvailable({
    required String username,
    required String userId,
  }) async {
    try {
      final available = await isUsernameAvailable(
        username: username,
        userId: userId,
      );

      if (!available) {
        throw const UserProfileUpdateException(
          'That username is already taken.',
        );
      }
    } on UserProfileUpdateException {
      rethrow;
    } on PostgrestException catch (error) {
      // RPC not deployed yet — rely on the unique index during insert/update.
      final message = error.message.toLowerCase();
      if (!message.contains('is_username_available') &&
          !message.contains('could not find the function')) {
        throw _mapPostgrestError(error);
      }
    }
  }

  @visibleForTesting
  static bool parseAvailabilityForTest(dynamic available) =>
      _parseAvailability(available);

  static bool _parseAvailability(dynamic available) {
    if (available is bool) {
      return available;
    }
    if (available is String) {
      return available.toLowerCase() == 'true';
    }
    return false;
  }

  @visibleForTesting
  static bool isUsernameUniqueViolationForTest({
    required String? code,
    required String message,
    String? details,
  }) =>
      _isUsernameUniqueViolation(code, message, details);

  UserProfileUpdateException _mapPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (_isUsernameUniqueViolation(
      error.code,
      message,
      error.details?.toString(),
    )) {
      return const UserProfileUpdateException(
        'That username is already taken.',
      );
    }
    if (message.contains('row-level security')) {
      return const UserProfileUpdateException(
        'You do not have permission to save this profile yet.',
      );
    }
    return UserProfileUpdateException(
      error.message.isNotEmpty
          ? error.message
          : 'Could not save profile. Please try again.',
    );
  }

  static bool _isUsernameUniqueViolation(
    String? code,
    String message,
    String? details,
  ) {
    final haystack = '$message ${details ?? ''}'.toLowerCase();

    if (haystack.contains('users_username_lower_idx') ||
        haystack.contains('users_username_idx')) {
      return true;
    }

    if (code == '23505') {
      return haystack.contains('username');
    }

    return false;
  }
}

class UserProfileUpdateException implements Exception {
  const UserProfileUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}