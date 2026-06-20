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
    final existing = await fetchById(userId);
    if (existing == null) {
      return _insert(
        userId: userId,
        username: username,
        fullName: fullName,
        bio: bio,
      );
    }

    return _update(
      userId: userId,
      username: username,
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

  UserProfileUpdateException _mapPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (_isUsernameUniqueViolation(error.code, message)) {
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

  bool _isUsernameUniqueViolation(String? code, String message) {
    if (code != '23505') {
      return false;
    }

    return message.contains('users_username_lower_idx') ||
        message.contains('users_username_idx') ||
        message.contains('username');
  }
}

class UserProfileUpdateException implements Exception {
  const UserProfileUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}