import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson({
    required String username,
    String? fullName,
    String? bio,
  }) {
    return {
      'username': username,
      'full_name': fullName,
      'bio': bio,
    };
  }
}