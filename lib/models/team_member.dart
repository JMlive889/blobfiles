import 'package:flutter/foundation.dart';

@immutable
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.role,
    this.username,
    this.fullName,
  });

  final String userId;
  final String role;
  final String? username;
  final String? fullName;

  String get roleLabel {
    if (role.isEmpty) {
      return 'Member';
    }
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  String get displayName {
    final name = username?.trim();
    if (name != null && name.isNotEmpty) {
      return name.startsWith('@') ? name : '@$name';
    }

    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) {
      return full;
    }

    return 'Unknown member';
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final userJson = json['users'];
    final user = userJson is Map
        ? Map<String, dynamic>.from(userJson)
        : <String, dynamic>{};

    return TeamMember(
      userId: _asString(user['id']) ?? _asString(json['user_id']) ?? '',
      role: _asString(json['role']) ?? 'member',
      username: _asString(user['username']),
      fullName: _asString(user['full_name']),
    );
  }

  static String? _asString(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}